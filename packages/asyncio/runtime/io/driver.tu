// Reactor over netio.Poll. turn() blocks until at least one event fires
// (or the wakeup eventfd / timeout triggers), routes each event to the
// matching ScheduledIo, and clears the readiness slot.
// Token reservations: 0 = wakeup (cross-thread eventfd), 1 = signal driver.
// All other tokens are ScheduledIo* cast to u64.

use asyncio.util

use runtime
use std.atomic
use io as libio
use netio
use netio.event
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
}

// Cross-thread companion to IoDriver. Owns the registry view + waker so
// schedulers and Registration can register sources / kick the reactor.
mem IoHandle {
    u64                registry_slot  // Registry* raw bits
    RegistrationSet*   registrations
    runtime.MutexInter* synced_lock   // serialises registrations
    u64                waker_slot     // Waker* raw bits
    Metrics*           metrics
}

// Build (driver, handle) wired together. Allocates the netio.Poll and the
// wakeup eventfd; subsequent registrations route through handle.
const IoDriver::new() i32, IoDriver, IoHandle {
    err<i32>, p<Poll> = make_poll()
    if err != 0 {
        return err, null, null
    }

    events_buf<Events> = make_events(EVENTS_CAPACITY)

    drv<IoDriver> = new IoDriver
    drv.signal_ready = 0
    drv.events_slot  = events_buf.(u64)
    drv.poll_slot    = p.(u64)

    reg<Registry> = poll_registry(p)
    h<IoHandle> = new IoHandle
    h.registry_slot  = reg.(u64)
    h.registrations  = RegistrationSet::new()
    h.synced_lock    = new runtime.MutexInter
    h.synced_lock.init()
    h.metrics        = Metrics::new()

    werr<i32>, wk<Waker> = make_waker(reg, token_from_u64(TOKEN_WAKEUP))
    if werr != 0 {
        return werr, null, null
    }
    h.waker_slot = wk.(u64)

    return 0, drv, h
}

// Register a source. Token is the new ScheduledIo* cast to u64; later
// turn() reverses the cast to dispatch the event back.
IoHandle::add_source(io_obj<Source>, interest<netio.Interest>) i32, ScheduledIo {
    err<i32>, sio<ScheduledIo> = this.registrations.allocate(interest)
    if err != 0 {
        return err, null
    }
    reg<Registry> = registry_from_bits(this.registry_slot)
    this.synced_lock.lock()
    rerr<i32> = registry_register(reg, io_obj, token_from_u64(sio.token()), interest)
    this.synced_lock.unlock()
    if rerr != 0 {
        this.registrations.release(sio)
        return rerr, null
    }
    return 0, sio
}

// Cross-thread wake: writes to the eventfd, which surfaces in turn() as a
// TOKEN_WAKEUP event the driver swallows.
IoHandle::wake_by_ref() i32 {
    wk<Waker> = waker_from_bits(this.waker_slot)
    return waker_wake(wk)
}

// Detach a previously registered source. Caller passes the original
// libio.event.Source object (so netio can extract the fd) plus the
// ScheduledIo* it received from add_source.
IoHandle::remove_source(io_obj<Source>, sio<ScheduledIo>) i32 {
    reg<Registry> = registry_from_bits(this.registry_slot)
    this.synced_lock.lock()
    err<i32> = registry_deregister(reg, io_obj)
    this.synced_lock.unlock()
    this.registrations.release(sio)
    return err
}

// Drain everything. Called on runtime shutdown; every waiter then observes
// OtherDriverTerminated on its next poll_readiness or Readiness::poll.
IoHandle::shutdown(){
    this.registrations.drain_all_for_shutdown()
}

// Block on the netio poll. Each event is dispatched to the matching
// ScheduledIo: set_readiness merges fresh bits, then wake() drains all
// waiters whose interest overlaps. Reserved tokens are recognised first.
// Interrupted maps to a no-op turn so the caller can re-park as needed.
IoDriver::turn(handle<IoHandle>, max_wait<sys.Duration>) i32 {
    err<i32> = poll_poll(poll_from_bits(this.poll_slot), events_from_bits(this.events_slot), max_wait)
    if err == libio.Interrupted return 0
    if err != 0 return err

    iter<Iter> = events_begin_iter(events_from_bits(this.events_slot))
    fired<u64> = 0
    loop {
        ie<i32>, ev<Event> = events_iter_next(iter)
        if ie != 0 break

        token<u64> = ev.token()
        if token == TOKEN_WAKEUP continue
        if token == TOKEN_SIGNAL {
            this.signal_ready = 1
            continue
        }

        sio<ScheduledIo> = token.(ScheduledIo)
        ready<Ready> = ready_from_event(ev)
        sio.set_readiness(TICK_INC, ready.bits)
        wakes<util.WakeList> = sio.wake(ready)
        // The reactor surfaces ctx_packed values to its caller; the
        // current first-pass impl drops them here because the scheduler
        // glue layer (task 11.x) has not landed yet. Once the runtime
        // root is ready, hand wakes back to the scheduler instead.
        util.wake_list_clear(wakes)
        fired += 1
    }

    if fired > 0 {
        metrics_incr_ready_count_by(handle.metrics, fired)
    }
    return 0
}
