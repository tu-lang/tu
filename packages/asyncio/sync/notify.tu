// Wake-once / wake-all primitive backed by an intrusive waiter list.
//   notify_one()       — wake the queue head, or stash one permit when empty.
//   notify_waiters()   — wake every currently-queued waiter (no permit).
//   await notified()   — yield until either a wake hits us or a permit was
//                        already pending.

use runtime
use asyncio.task as task

// notify_one permit accounting. Only NONE and ONE are used today; the
// ALL flag is reserved for a future "broadcast" extension.
NOTIFY_NONE<i32> = 0
NOTIFY_ONE<i32>  = 1
NOTIFY_ALL<i32>  = 2

// Notified future stages. 0 = before first poll, 1 = queued, 2 = done.
NOTIFIED_STAGE_INIT<i32>    = 0
NOTIFIED_STAGE_WAITING<i32> = 1
NOTIFIED_STAGE_DONE<i32>    = 2

// One queued waiter; placed on Notify.waiter_q via the embedded Pointers.
mem NotifyWaiter {
    Pointers node           // intrusive prev/next; offset 0
    u64      ctx_packed     // (sched, task_id) the wake side schedules
    i32      woke_flag      // monotonic 0 -> 1 once dequeued by a wake
}

// Build a fresh waiter ready to be linked. `new NotifyWaiter` returns the
// heap pointer; pass it through (no `&`).
const NotifyWaiter::new(ctx<u64>) NotifyWaiter {
    w<NotifyWaiter> = new NotifyWaiter
    w.node.prev    = null
    w.node.next    = null
    w.ctx_packed   = ctx
    w.woke_flag    = 0
    return w
}

// Notify itself. waiter_q is the queue of pending Notified futures; permit_slot
// holds at most one queued permit when no waiter is around to consume it.
mem Notify {
    runtime.MutexInter* lock
    i32         permit_slot    // permit slot; only NONE / ONE used
    LinkedList* waiter_q
}

// Build an empty Notify in the NOTIFY_NONE state.
const Notify::new() Notify {
    n<Notify> = new Notify
    n.lock = new runtime.MutexInter
    n.lock.init()
    n.permit_slot = NOTIFY_NONE
    n.waiter_q    = LinkedList::new()
    return n
}

// True when a stashed NOTIFY_ONE permit is pending.
Notify::has_permit() i32 {
    if this.permit_slot == NOTIFY_ONE return 1
    return 0
}

// Consume a stashed NOTIFY_ONE permit; returns 1 when consumed.
Notify::take_permit() i32 {
    if this.permit_slot == NOTIFY_ONE {
        this.permit_slot = NOTIFY_NONE
        return 1
    }
    return 0
}

// Stash a NOTIFY_ONE permit when no waiter is queued.
Notify::stash_permit(){
    if this.permit_slot == NOTIFY_NONE this.permit_slot = NOTIFY_ONE
}

// Hand off to one waiter, or stash a single permit when none are queued.
// Returns NOTIFY_ONE when a permit was stashed, NOTIFY_NONE when a waiter
// was woken (the wake itself happens after the lock drops).
// Mother: waker.wake() after dequeue.
Notify::notify_one() i32 {
    this.lock.lock()
    head_node<Pointers> = this.waiter_q.peek_head()
    if head_node == null {
        this.stash_permit()
        this.lock.unlock()
        return NOTIFY_ONE
    }
    this.waiter_q.remove(head_node)
    w<NotifyWaiter> = head_node.(NotifyWaiter)
    w.woke_flag = 1
    ctx_bits<u64> = w.ctx_packed
    this.lock.unlock()
    if ctx_bits != 0 {
        task.wake_by_ctx(ctx_bits)
    }
    return NOTIFY_NONE
}

// Wake every currently queued waiter; does NOT stash a permit. Waiters
// added after this call wait for the next notify.
// Mother: each waiter waker.wake().
Notify::notify_waiters(){
    this.lock.lock()
    loop {
        h<Pointers> = this.waiter_q.peek_head()
        if h == null break
        this.waiter_q.remove(h)
        w<NotifyWaiter> = h.(NotifyWaiter)
        w.woke_flag = 1
        ctx_bits<u64> = w.ctx_packed
        this.lock.unlock()
        if ctx_bits != 0 {
            task.wake_by_ctx(ctx_bits)
        }
        this.lock.lock()
    }
    this.lock.unlock()
}

// Async leaf future returned by Notify::notified().
mem Notified: async {
    Notify*        owner_notify
    i32            stage   // NOTIFIED_STAGE_*
    NotifyWaiter*  waiter_node    // null until first poll links us
}

// Initialise the future before the first poll.
Notified::init(owner_notify<Notify>){
    this.owner_notify = owner_notify
    this.stage  = NOTIFIED_STAGE_INIT
    this.waiter_node = null
}

// Three-stage state machine. INIT consumes a stashed permit if available;
// WAITING checks the wake flag; DONE re-poll is a logic error.
Notified::poll(ctx){
    par<Notify> = this.owner_notify
    // Harness Future::poll does not forward ctx; always prefer ACTIVE_POLL_CTX.
    // Passing a literal 0 into poll makes ctx.(u64) a dyn-int bit pattern
    // (non-zero garbage), which then crashes wake_by_ref on life_st().
    packed<u64> = task.resolve_poll_ctx(0)
    if this.stage == NOTIFIED_STAGE_INIT {
        par.lock.lock()
        if par.take_permit() != 0 {
            par.lock.unlock()
            this.stage = NOTIFIED_STAGE_DONE
            return runtime.PollReady, 0.(i64)
        }
        // No permit; queue ourselves.
        w<NotifyWaiter> = NotifyWaiter::new(packed)
        // Intrusive: pass address of embedded Pointers (offset 0), same as
        // ScheduledIo waiters — plain `w.node` is the wrong pointer shape.
        par.waiter_q.push_back(&w.node)
        par.lock.unlock()
        this.waiter_node = w
        this.stage = NOTIFIED_STAGE_WAITING
        return runtime.PollPending, 0.(i64)
    }
    if this.stage == NOTIFIED_STAGE_WAITING {
        wk<NotifyWaiter> = this.waiter_node
        if wk.woke_flag == 1 {
            this.stage = NOTIFIED_STAGE_DONE
            return runtime.PollReady, 0.(i64)
        }
        // Refresh ctx so the most recent waker wins.
        wk.ctx_packed = packed
        return runtime.PollPending, 0.(i64)
    }
    // Already DONE; behaves like AlreadyConsumed.
    return runtime.PollReady, 0.(i64)
}

// Public entry point. Builds the future; caller must `await` it.
async Notify::notified(){
    fut<Notified> = new Notified
    fut.init(this)
    code<i32> = fut.await
    return code
}

// Initialise from a cross-package u64 Notify* slot.
Notified::init_from_bits(bits<u64>){
    this.owner_notify = bits.(Notify)
    this.stage  = NOTIFIED_STAGE_INIT
    this.waiter_node = null
}

// Cross-package bridges: heap Notify* stored as u64 in foreign mem layouts.
fn notify_new_raw() u64 {
    n<Notify> = Notify::new()
    return n.(u64)
}

fn notify_one_raw(bits<u64>) {
    par<Notify> = bits.(Notify)
    par.notify_one()
}

fn notify_waiters_raw(bits<u64>) {
    if bits == 0 {
        return
    }
    par<Notify> = bits.(Notify)
    par.notify_waiters()
}

// Factory for await at the call site (no package-level async).
fn notified_from_bits(bits<u64>) Notified {
    fut<Notified> = new Notified{}
    fut.init_from_bits(bits)
    return fut
}

// Cross-pkg poll — foreign packages must not member-call Notified::poll
// (codegen null-dispatch → SIGSEGV). Uses ACTIVE_POLL_CTX like mother.
fn notified_poll_bits(nf_bits<u64>) i32 {
    if nf_bits == 0 {
        return runtime.PollPending
    }
    nfy<Notified> = null
    nfy = nf_bits
    code<i32> = nfy.poll(0)
    return code
}

// Same-package helper: build Notified from a Notify heap pointer.
fn notified_from_notify(n<Notify>) Notified {
    fut<Notified> = new Notified
    fut.init(n)
    return fut
}
