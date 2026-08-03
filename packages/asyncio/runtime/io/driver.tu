// Reactor over netio.Poll. turn() blocks until at least one event fires
// (or the wakeup eventfd / timeout triggers), routes each event to the
// matching ScheduledIo, and clears the readiness slot.
// Token reservations: 0 = wakeup (cross-thread eventfd), 1 = signal driver.
// All other tokens are ScheduledIo* cast to u64.

use asyncio.util
use asyncio.task

use runtime
use std.atomic
use io
use netio
use netio.event as netevent
use netio.sys as nsys
use sys

TOKEN_WAKEUP<u64> = 0
TOKEN_SIGNAL<u64> = 1

// Default events buffer capacity; fixed for the first-pass impl.
EVENTS_CAPACITY<u64> = 1024

// Reactor state held by the dedicated driver thread / block_on park path.
mem IoDriver {
    i32 signal_ready    // set to 1 when TOKEN_SIGNAL fires
    u64 events_slot     // Events* raw bits
    u64 poll_slot       // Poll* raw bits
    i32 io_hit          // non-wakeup/non-signal events dispatched this turn
}

// Cross-thread companion to IoDriver. Owns the registry view + waker so
// schedulers and Registration can register sources / kick the reactor.
mem IoHandle {
    u64                     registry_slot  // Registry* raw bits
    RegistrationSet*        registrations
    RegistrationSetSynced*  synced         // the design Synced; guarded by synced_lock
    runtime.MutexInter*     synced_lock
    u64                     waker_slot     // Waker* raw bits
    Metrics*                metrics
}

// Last successful IoDriver::new results. Consumers use iodriver_last /
// iohandle_last — (i32, mem...) multi-ret and cross-pkg mem field reads
// drop or zero the handle (same trap as make_poll's dummy-arg pattern).
LAST_IODRIVER<IoDriver> = null
LAST_IOHANDLE<IoHandle> = null

fn iodriver_last() IoDriver {
    return LAST_IODRIVER
}
fn iohandle_last() IoHandle {
    return LAST_IOHANDLE
}

// Build (driver, handle) wired together. Allocates the netio.Poll and the
// wakeup eventfd; subsequent registrations route through handle.
// Publishes the pair via iodriver_last / iohandle_last.
const IoDriver::new() i32 {
    LAST_IODRIVER = null
    LAST_IOHANDLE = null
    err<i32>, p<netio.Poll> = netio.make_poll(0)
    // netio/io use Ok=1 (not 0) as success.
    if err != io.Ok {
        return err
    }

    events_buf<netevent.Events> = netevent.make_events(EVENTS_CAPACITY)

    drv<IoDriver> = new IoDriver
    drv.signal_ready = 0
    drv.io_hit = 0
    drv.events_slot  = events_buf.(u64)
    drv.poll_slot    = p.(u64)

    reg<netio.Registry> = netio.poll_registry(p)
    h<IoHandle> = new IoHandle
    h.registry_slot = reg.(u64)
    RegistrationSet::new()
    h.registrations = registration_set_last()
    h.synced = registration_synced_last()
    lk<runtime.MutexInter> = new runtime.MutexInter
    lk.init()
    h.synced_lock = lk
    h.metrics = Metrics::new()
    werr<i32>, wk<netio.Waker> = netio.make_waker(reg, netio.token_from_u64(TOKEN_WAKEUP))
    if werr != io.Ok {
        return werr
    }
    h.waker_slot = wk.(u64)
    LAST_IODRIVER = drv
    LAST_IOHANDLE = h
    return 0
}

// Register a source via event.Source api (InitApiVptr on coerce at call sites).
// iosrc_bits is retained for shutdown close (Source has no close slot).
IoHandle::add_source(src<netevent.Source>, iosrc_bits<u64>, interest<netio.Interest>) i32, ScheduledIo {
    if this.registrations == null || this.synced == null {
        return 1, null
    }
    lk<runtime.MutexInter> = this.synced_lock
    lk.lock()
    err<i32>, sio<ScheduledIo> = this.registrations.allocate(this.synced)
    lk.unlock()
    if err != 0 {
        return err, null
    }
    reg<netio.Registry> = netio.registry_from_bits(this.registry_slot)
    tok<u64> = sio.token()
    t<netio.Token> = netio.token_from_u64(tok)
    rerr<i32> = netio.registry_register(reg, src, t, interest)
    if rerr != io.Ok {
        lk.lock()
        this.registrations.remove(this.synced, sio)
        lk.unlock()
        return rerr, null
    }
    sio.iosrc_bits = iosrc_bits
    return 0, sio
}

// Cross-thread wake: writes to the eventfd, which surfaces in turn() as a
// TOKEN_WAKEUP event the driver swallows.
IoHandle::wake_by_ref() i32 {
    wk<netio.Waker> = netio.waker_from_bits(this.waker_slot)
    return netio.waker_wake(wk)
}

// Cross-pkg unpark: schedulers hold IoHandle only as u64 bits.
fn io_handle_wake_bits(ioh_bits<u64>) i32 {
    if ioh_bits == 0 return 0
    ih<IoHandle> = ioh_bits
    return ih.wake_by_ref()
}

// Register signalfd with TOKEN_SIGNAL.
// Named register_sfd — callers in asyncio.runtime.signal must not write
// `.register_signal_*` (type-assert trap on `signal` in that package).
IoHandle::register_sfd(fd<i32>) i32 {
    if this.registry_slot == 0 return 1
    reg<netio.Registry> = netio.registry_from_bits(this.registry_slot)
    sel<nsys.Selector> = netio.registry_selector(reg)
    tok<u64> = TOKEN_SIGNAL
    return sel.register_readable(fd, tok)
}

// Clear and return prior flag.
IoDriver::consume_signal_ready() i32 {
    if this.signal_ready == 0 return 0
    this.signal_ready = 0
    return 1
}

fn iodriver_consume_signal_ready_bits(iod_bits<u64>) i32 {
    if iod_bits == 0 return 0
    iod<IoDriver> = null
    iod = iod_bits
    if iod.signal_ready == 0 return 0
    iod.signal_ready = 0
    return 1
}

// Detach by IoSource bits (stable after multi-api view flips overwrite vptr@0).
// Phase-2 wake-all on close deferred: sio.wake(ALL) here hung
// int_mt_stress_spawn (re-entrancy / lost-wakeup under concurrent close).
IoHandle::remove_source(iosrc_bits<u64>, sio<ScheduledIo>) i32 {
    reg<netio.Registry> = netio.registry_from_bits(this.registry_slot)
    err<i32> = netio.registry_deregister_bits(reg, iosrc_bits)
    sio.iosrc_bits = 0
    lk<runtime.MutexInter> = this.synced_lock
    lk.lock()
    need_wake<i32> = this.registrations.deregister(this.synced, sio)
    lk.unlock()
    if need_wake != 0 {
        this.wake_by_ref()
    }
    return err
}

// Drain everything. Called on runtime shutdown; every waiter then observes
// OtherDriverTerminated on its next poll_readiness or Readiness::poll.
// Also deregister + close each remaining IoSource fd so the next runtime
// can rebind the same UDP/TCP ports (no Drop in Tu — this is the RAII path).
IoHandle::shutdown(){
    if this.registrations == null || this.synced == null {
        return
    }
    if this.synced_lock == null {
        return
    }
    lk<runtime.MutexInter> = this.synced_lock
    lk.lock()
    head<ScheduledIo> = this.registrations.shutdown(this.synced)
    lk.unlock()
    reg<netio.Registry> = null
    if this.registry_slot != 0 {
        reg = netio.registry_from_bits(this.registry_slot)
    }
    cur<ScheduledIo> = head
    while cur != null {
        nxt<ScheduledIo> = cur.next_sio
        bits<u64> = cur.iosrc_bits
        if bits != 0 && reg != null {
            netio.registry_deregister_bits(reg, bits)
            netio.iosource_close_fd(bits)
            cur.iosrc_bits = 0
        }
        wakes<util.WakeList> = cur.shutdown()
        wi<i32> = 0
        wlen<i32> = wakes.len_count()
        while wi < wlen {
            task.wake_by_ctx(wakes.ctxs[wi])
            wi += 1
        }
        util.wake_list_clear(wakes)
        cur = nxt
    }
}

IoHandle::release_pending_registrations(){
    if this.registrations.needs_release() == 0 {
        return
    }
    lk<runtime.MutexInter> = this.synced_lock
    lk.lock()
    this.registrations.release(this.synced)
    lk.unlock()
}

// Block on the netio poll. Each event is dispatched to the matching
// ScheduledIo: set_readiness merges fresh bits, then wake() drains all
// waiters whose reason interest overlaps. Reserved tokens first.
// Interrupted maps to a no-op turn so the caller can re-park as needed.
//
// release_pending runs AFTER dispatch: epoll may still surface a token for a
// source that deregistered since the previous turn; freeing before poll UAF.
IoDriver::turn(handle<IoHandle>, max_wait<sys.Duration>) i32 {
    this.io_hit = 0
    err<i32> = netio.poll_poll(netio.poll_from_bits(this.poll_slot), netevent.events_from_bits(this.events_slot), max_wait)
    if err == io.Interrupted {
        handle.release_pending_registrations()
        return 0
    }
    if err != io.Ok {
        handle.release_pending_registrations()
        return err
    }

    iter<netevent.Iter> = netevent.events_begin_iter(netevent.events_from_bits(this.events_slot))
    fired<u64> = 0
    loop {
        ie<i32>, ev<netevent.Event> = netevent.events_iter_next(iter)
        // io.Ok is 1 — must not use `ie != 0` (that drops every successful event).
        if ie != io.Ok break

        token<u64> = ev.token()
        if token == TOKEN_WAKEUP continue
        // Padded Event (u32+u64) makes epoll_ctl store TOKEN_SIGNAL as 1<<32;
        // epoll_wait may surface either form depending on slot packing.
        tok_sig_alt<u64> = 4294967296
        if token == TOKEN_SIGNAL || token == tok_sig_alt {
            this.signal_ready = 1
            continue
        }

        this.io_hit = 1
        sio<ScheduledIo> = token.(ScheduledIo)
        // Dropped sources stay reachable via pending_slots until release at
        // end of turn; ignore readiness once iosrc was cleared on deregister.
        if sio == null || sio.iosrc_bits == 0 {
            continue
        }
        ready<Ready> = ready_from_event(ev)
        sio.set_readiness(TICK_INC, ready.bits)
        wakes<util.WakeList> = sio.wake(ready)
        // ctx slots hold RawTask* (see ct_task_ctx / mt_ctx).
        wi<i32> = 0
        wlen<i32> = wakes.len_count()
        while wi < wlen {
            task.wake_by_ctx(wakes.ctxs[wi])
            wi += 1
        }
        util.wake_list_clear(wakes)
        fired += 1
    }

    if fired > 0 {
        metrics_incr_ready_count_by(handle.metrics, fired)
    }
    handle.release_pending_registrations()
    return 0
}

// Cross-pkg: whether the last turn dispatched real IO (not just wakeup).
fn iodriver_took_io(iod<IoDriver>) i32 {
    if iod == null {
        return 0
    }
    return iod.io_hit
}
