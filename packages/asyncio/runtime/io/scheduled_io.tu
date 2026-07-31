// Per-IO-resource shadow tracked by the IO Driver. Holds packed readiness
// bits, a tick counter, a shutdown flag, and an intrusive list of waiters.
// Tokens registered with netio.Registry are ScheduledIo* cast to u64.

use runtime
use std.atomic
use netio

use asyncio.util
use asyncio.task

// CAS success sentinel: std.atomic cas/cas64 return 1 on success;
// comparing against an untyped literal 0 crashes codegen (binary-op trap).
CAS64_OK<i64> = 1

// readiness packing: [shutdown:1 | tick:15 | readiness:16].
READINESS_BITS<i32> = 16
TICK_BITS<i32>      = 15
SHUTDOWN_BITS<i32>  = 1

// Direction for poll_readiness; matches Interest bit ordering.
DIR_READ<i32>  = 0
DIR_WRITE<i32> = 1

// Set / increment tick semantics on set_readiness. Set keeps tick as-is;
// Increment bumps tick under the same CAS so concurrent clear_readiness
// against an older snapshot is rejected.
TICK_SET<i32> = 0
TICK_INC<i32> = 1

// Pre-built bit packs over the readiness u64. Built lazily in package
// init() since module-level expressions are not a Tu convention.
ready_pack<util.Pack>    = null
tick_pack<util.Pack>     = null
shutdown_pack<util.Pack> = null
PACKS_READY<i32>         = 0

// Lazily build pack singletons. Package init() is not always run before the
// first shutdown path, so every consumer calls ensure_packs() first.
fn ensure_packs(){
    if PACKS_READY != 0 {
        return
    }
    rp<util.Pack> = util.Pack::least_significant(READINESS_BITS)
    tp<util.Pack> = util.pack_then_next(rp, TICK_BITS)
    sp<util.Pack> = util.pack_then_next(tp, SHUTDOWN_BITS)
    ready_pack    = rp
    tick_pack     = tp
    shutdown_pack = sp
    PACKS_READY   = 1
}

// Wire the bit-pack singletons. Called once on package load when init runs.
func init(){
    ensure_packs()
}

// One queued waiter on a ScheduledIo. Embedded via Pointers at offset 0.
mem Waiter {
    util.Pointers       node           // intrusive prev/next; must stay at offset 0
    u64            ctx_packed     // (sched, task_id) the driver re-schedules
    u8             interest_bits  // netio.Interest.bits snapshot
    i32            is_ready       // 1 once ScheduledIo::wake matched this waiter
}

// Build a Waiter ready to be linked.
const Waiter::new(ctx<u64>, interest_bits<u8>) Waiter {
    w<Waiter> = new Waiter
    w.node.prev   = null
    w.node.next   = null
    w.ctx_packed  = ctx
    w.interest_bits = interest_bits
    w.is_ready    = 0
    return w
}

// IO Driver shadow for one source. Lives on the RegistrationSet owning
// list via typed prev_sio / next_sio links (GC-traced strong refs — the design
// keeps Arc<ScheduledIo> in Synced; interior Pointers links are invisible
// to the GC and caused use-after-free). Tokens registered with
// netio.Registry are ScheduledIo* cast to u64 (weak; list keeps it alive).
mem ScheduledIo {
    ScheduledIo*       prev_sio         // owning list link (registration_set)
    ScheduledIo*       next_sio         // owning list link (registration_set)
    u64                readiness        // atomic; packed bits above
    runtime.MutexInter* waiters_lock
    util.LinkedList*   waiters          // intrusive list of Waiter
    u64                reader_ctx       // poll_readiness(DIR_READ) ctx slot
    u64                writer_ctx       // poll_readiness(DIR_WRITE) ctx slot
    u64                iosrc_bits       // IoSource* bits; 0 after deregister/close
}

// Build an empty ScheduledIo: no readiness, no waiters, no shutdown.
const ScheduledIo::new() ScheduledIo {
    ensure_packs()
    s<ScheduledIo> = new ScheduledIo
    s.prev_sio = null
    s.next_sio = null
    s.readiness = 0
    s.iosrc_bits = 0
    wl<runtime.MutexInter> = new runtime.MutexInter
    wl.init()
    s.waiters_lock = wl
    s.waiters    = util.LinkedList::new()
    s.reader_ctx = 0
    s.writer_ctx = 0
    return s
}

// Token surfaced to netio.Registry — the ScheduledIo*'s raw bits.
ScheduledIo::token() u64 {
    return this.(u64)
}

// Decode helpers over the packed readiness word.
fn unpack_ready_bits(pack<u64>) i32 {
    ensure_packs()
    bits<u64> = util.pack_unpack_field(ready_pack, pack)
    return bits.(i32)
}
fn unpack_tick(pack<u64>) i32 {
    bits<u64> = util.pack_unpack_field(tick_pack, pack)
    return bits.(i32)
}
fn unpack_shutdown(pack<u64>) i32 {
    ensure_packs()
    bits<u64> = util.pack_unpack_field(shutdown_pack, pack)
    return bits.(i32)
}

// True when SHUTDOWN bit is set in pack.
fn pack_is_shutdown(pack<u64>) i32 {
    if unpack_shutdown(pack) != 0 return 1
    return 0
}

// CAS retry that combines new_ready bits with the previous ready bits via
// OR. When tick_op == TICK_INC the
// tick field is bumped under the same CAS so older snapshots can be
// rejected by clear_readiness.
ScheduledIo::set_readiness(tick_op<i32>, new_ready_bits<i32>) i32 {
    ensure_packs()
    loop {
        cur<u64> = atomic.load64(&this.readiness)
        if pack_is_shutdown(cur) return IO_OTHER_DRIVER_TERMINATED

        cur_ready<i32> = unpack_ready_bits(cur)
        merged_ready<i32> = cur_ready | new_ready_bits
        next_tick<i32> = unpack_tick(cur)
        if tick_op == TICK_INC {
            next_tick = (next_tick + 1) & 0x7FFF
        }

        nxt<u64> = util.pack_pack_field(ready_pack, merged_ready.(u64), cur)
        nxt = util.pack_pack_field(tick_pack, next_tick.(u64), nxt)
        if atomic.cas64(&this.readiness, cur.(i64), nxt.(i64)) == CAS64_OK return 0
    }
    return 0
}

// Build the snapshot tag clear_readiness uses to avoid clobbering bits
// observed after the caller's poll.
ScheduledIo::ready_event(interest<netio.Interest>) ReadyEvent {
    cur<u64> = atomic.load64(&this.readiness)
    bits<i32> = unpack_ready_bits(cur) & interest_to_ready_mask(interest)
    return ReadyEvent::new(unpack_tick(cur), Ready::from_bits(bits))
}

// Translate Interest bits into the matching Ready mask.
fn interest_bits_to_ready_mask(interest_bits<u8>) i32 {
    mask<i32> = 0
    if (interest_bits & 1) != 0 mask = mask | READABLE | READ_CLOSED | ERROR | PRIORITY
    if (interest_bits & 2) != 0 mask = mask | WRITABLE | WRITE_CLOSED | ERROR
    return mask
}

// Translate an Interest into the matching Ready mask.
fn interest_to_ready_mask(interest<netio.Interest>) i32 {
    return interest_bits_to_ready_mask(netio.interest_as_u8(interest))
}

// Wake every waiter whose interest overlaps `ready`. Matched waiters are
// flagged is_ready=1 and their ctx is handed back to the caller via the
// returned WakeList; reader_ctx / writer_ctx are also drained. The driver
// schedules wakes outside the lock.
ScheduledIo::wake(ready<Ready>) util.WakeList {
    out<util.WakeList> = new util.WakeList
    out.init()

    wl<runtime.MutexInter> = this.waiters_lock
    wl.lock()

    // Single-direction shortcuts first: reader_ctx handles READABLE/closed/err,
    // writer_ctx handles WRITABLE/closed/err. Drained on first match.
    if (ready.is_readable() || ready.is_read_closed() || ready.is_error()) {
        if this.reader_ctx != 0 {
            out.push(this.reader_ctx)
            this.reader_ctx = 0
        }
    }
    if (ready.is_writable() || ready.is_write_closed() || ready.is_error()) {
        if this.writer_ctx != 0 {
            out.push(this.writer_ctx)
            this.writer_ctx = 0
        }
    }

    // Walk the waiter list FIFO; matched waiters are removed and queued for
    // schedule. Waiters whose interest does not overlap stay in place.
    cur<util.Pointers> = this.waiters.head
    while cur != null {
        nxt<util.Pointers> = cur.next
        w<Waiter> = cur.(Waiter)
        match_mask<i32> = interest_bits_to_ready_mask(w.interest_bits)
        if (ready.bits & match_mask) != 0 {
            this.waiters.remove(cur)
            w.is_ready = 1
            if w.ctx_packed != 0 out.push(w.ctx_packed)
        }
        cur = nxt
    }

    wl.unlock()
    return out
}

// Single-direction poll. Return convention (repair-plan E2 / callers):
//   0              — ready; ReadyEvent carries the hit bits
//   PollPending    — parked; waker stored in reader/writer slot
//   OtherDriverTerminated — driver shut down
// Must NOT return PollReady(=1): callers use `err != 0` / `err == 0`, and
// PollReady collides with io.Ok(=1) so readiness was treated as an error.
// The design scheduled_io.rs poll_readiness: on miss, store the waker under
// the waiters lock, then RE-READ readiness — a wake landing between the
// first load and the store would otherwise be lost (TOCTOU).
ScheduledIo::poll_readiness(ctx<u64>, dir<i32>) i32, ReadyEvent {
    interest_mask<i32> = 0
    if dir == DIR_READ  interest_mask = READABLE | READ_CLOSED | ERROR | PRIORITY
    if dir == DIR_WRITE interest_mask = WRITABLE | WRITE_CLOSED | ERROR

    cur<u64> = atomic.load64(&this.readiness)
    hit<i32> = unpack_ready_bits(cur) & interest_mask
    is_sd<i32> = pack_is_shutdown(cur)

    if hit == 0 && is_sd == 0 {
        // Stash the task waker. Prefer the
        // harness-published RawTask* when dynstackcall null-padded the ctx.
        wl<runtime.MutexInter> = this.waiters_lock
        wl.lock()
        wake_ctx<u64> = task.resolve_poll_ctx(ctx)
        if dir == DIR_READ  this.reader_ctx = wake_ctx
        if dir == DIR_WRITE this.writer_ctx = wake_ctx
        // Re-read while holding the lock: wake() takes the same lock, so a
        // concurrent readiness change is either visible here or will see
        // the waker we just stored.
        cur = atomic.load64(&this.readiness)
        hit = unpack_ready_bits(cur) & interest_mask
        is_sd = pack_is_shutdown(cur)
        wl.unlock()
        if is_sd == 0 && hit == 0 {
            return runtime.PollPending, ReadyEvent::new(unpack_tick(cur), Ready::empty())
        }
    }

    if is_sd != 0 {
        // The design returns Ready with direction.mask() + is_shutdown; Tu
        // surfaces the terminated error code instead.
        return IO_OTHER_DRIVER_TERMINATED, ReadyEvent::new(unpack_tick(cur), Ready::from_bits(interest_mask))
    }
    return 0, ReadyEvent::new(unpack_tick(cur), Ready::from_bits(hit))
}

// Clear `event.ready` from the readiness word, but only if tick still
// matches. A different tick means another set_readiness pass already
// swept past the snapshot, so the bits remain valid.
// The design clear_readiness: mask_no_closed = ready - READ_CLOSED - WRITE_CLOSED;
// closed bits are permanent (EOF / half-close never un-happens) — clearing
// them would leave the resource permanently Pending after EOF.
ScheduledIo::clear_readiness(event<ReadyEvent>) i32 {
    ensure_packs()
    mask_no_closed<i32> = event.ready.bits & (~(READ_CLOSED | WRITE_CLOSED))
    loop {
        cur<u64> = atomic.load64(&this.readiness)
        if unpack_tick(cur) != event.tick return 0
        cur_ready<i32> = unpack_ready_bits(cur)
        next_ready<i32> = cur_ready & (~mask_no_closed)
        nxt<u64> = util.pack_pack_field(ready_pack, next_ready.(u64), cur)
        if atomic.cas64(&this.readiness, cur.(i64), nxt.(i64)) == CAS64_OK return 0
    }
    return 0
}

// Flip the SHUTDOWN bit and wake every waiter with OtherDriverTerminated.
// All callers entering after shutdown observe the bit and bail out.
// Flip the SHUTDOWN bit and wake every waiter with OtherDriverTerminated.
// The design scheduled_io.rs shutdown(): fetch_or(SHUTDOWN) then wake(Ready::ALL).
// KNOWN OPEN ISSUE: crashes at runtime when >=1 live registration exists at
// Runtime::shutdown_background — suspected GC use-after-free on ScheduledIo
// reachable only via interior Pointers / u64 token (see repair-plan §7.6).
ScheduledIo::shutdown() util.WakeList {
    ensure_packs()
    loop {
        cur<u64> = atomic.load64(&this.readiness)
        if pack_is_shutdown(cur) != 0 {
            break
        }
        nxt<u64> = util.pack_pack_field(shutdown_pack, 1, cur)
        if atomic.cas64(&this.readiness, cur.(i64), nxt.(i64)) == CAS64_OK {
            break
        }
    }
    all<Ready> = Ready::from_bits(0xFFFF)
    return this.wake(all)
}

// Async leaf used by Registration::readiness(interest). Stays Pending
// until ScheduledIo::wake matches `interest` or the driver shuts down.
mem Readiness: async {
    ScheduledIo*    sio
    u8 interest_bits  // netio.Interest.bits snapshot
    Waiter*         node       // null until the first poll registers
    i32             registered // monotonic 0 -> 1 once node is in waiters
}

// Build the future without touching the wait list yet.
Readiness::init(sio<ScheduledIo>, interest<netio.Interest>){
    this.sio        = sio
    this.interest_bits = netio.interest_as_u8(interest)
    this.node       = null
    this.registered = 0
}

// Three states: shutdown/short-circuit ready / register ctx and yield.
// Returns (PollReady, ReadyEvent) on hit; (PollPending, empty) when queued;
// (PollError, OtherDriverTerminated) on shutdown.
Readiness::poll(ctx){
    sio<ScheduledIo> = this.sio
    cur<u64> = atomic.load64(&sio.readiness)
    if pack_is_shutdown(cur) {
        return runtime.PollError, IO_OTHER_DRIVER_TERMINATED
    }

    mask<i32> = interest_bits_to_ready_mask(this.interest_bits)
    hit<i32> = unpack_ready_bits(cur) & mask
    if hit != 0 {
        return runtime.PollReady, ReadyEvent::new(unpack_tick(cur), Ready::from_bits(hit))
    }

    // First poll: link a Waiter node with the ctx. Subsequent polls just
    // refresh ctx so the latest waker wins.
    if this.registered == 0 {
        w<Waiter> = Waiter::new(ctx.(u64), this.interest_bits)
        this.node = w
        this.registered = 1
        wl<runtime.MutexInter> = sio.waiters_lock
        wl.lock()
        sio.waiters.push_back(&w.node)
        wl.unlock()
    } else {
        n<Waiter> = this.node
        n.ctx_packed = ctx.(u64)
    }
    return runtime.PollPending
}

