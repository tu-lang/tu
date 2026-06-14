// Reactor over netio.Poll. turn() blocks until at least one event fires
// (or the wakeup eventfd / timeout triggers), routes each event to the
// matching ScheduledIo, and clears the readiness slot.
// Token reservations: 0 = wakeup (cross-thread eventfd), 1 = signal driver.
// All other tokens are ScheduledIo* cast to u64.

use runtime
use std.atomic
use io
use netio
use sys

TOKEN_WAKEUP<u64> = 0
TOKEN_SIGNAL<u64> = 1

// Default events buffer capacity; fixed for the first-pass impl.
EVENTS_CAPACITY<u64> = 1024

// Reactor state held by the dedicated driver thread / block_on park path.
mem IoDriver {
    i32                  signal_ready    // set to 1 when TOKEN_SIGNAL fires
    netio.event.Events*  events
    netio.Poll*          poll
}

// Cross-thread companion to IoDriver. Owns the registry view + waker so
// schedulers and Registration can register sources / kick the reactor.
mem IoHandle {
    netio.Registry*    registry
    RegistrationSet*   registrations
    runtime.MutexInter synced_lock     // serialises registrations
    netio.Waker*       waker           // eventfd-backed cross-thread wake
    Metrics*           metrics
}

// Build (driver, handle) wired together. Allocates the netio.Poll and the
// wakeup eventfd; subsequent registrations route through handle.
const IoDriver::new() (i32, IoDriver*, IoHandle*) {
    err<i32>, p<netio.Poll> = netio.Poll::new()
    if err != 0 {
        return err, null, null
    }

    events_buf<netio.event.Events> = netio.event.Events::with_capacity(EVENTS_CAPACITY)

    drv<IoDriver> = new IoDriver
    drv.signal_ready = 0
    drv.events       = &events_buf
    drv.poll         = &p

    h<IoHandle> = new IoHandle
    h.registry     = p.registry()
    h.registrations = RegistrationSet::new()
    h.synced_lock.init()
    h.metrics       = Metrics::new()

    werr<i32>, wk<netio.Waker> = netio.Waker::new(p.registry(), netio.Token::new(TOKEN_WAKEUP))
    if werr != 0 {
        return werr, null, null
    }
    h.waker = &wk

    return 0, &drv, &h
}

// Register a source. Token is the new ScheduledIo* cast to u64; later
// turn() reverses the cast to dispatch the event back.
IoHandle::add_source(io_obj<netio.event.Source>, interest<netio.Interest>) (i32, ScheduledIo*) {
    err<i32>, sio<ScheduledIo> = this.registrations.allocate(interest)
    if err != 0 {
        return err, null
    }
    this.synced_lock.lock()
    rerr<i32> = this.registry.register(io_obj, netio.Token::new(sio.token()), interest)
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
    return this.waker.wake()
}

// Detach a previously registered source. Caller passes the original
// io.event.Source object (so netio can extract the fd) plus the
// ScheduledIo* it received from add_source.
IoHandle::remove_source(io_obj<netio.event.Source>, sio<ScheduledIo>) i32 {
    this.synced_lock.lock()
    err<i32> = this.registry.deregister(io_obj)
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
    err<i32> = this.poll.poll(this.events, max_wait)
    if err == io.Interrupted return 0
    if err != 0 return err

    iter<netio.event.Iter> = this.events.iter()
    fired<u64> = 0
    loop {
        ie<i32>, ev<netio.event.Event> = iter.next()
        if ie != 0 break

        token<u64> = ev.token().as_u64()
        if token == TOKEN_WAKEUP continue
        if token == TOKEN_SIGNAL {
            this.signal_ready = 1
            continue
        }

        sio<ScheduledIo> = token.(ScheduledIo)
        ready<Ready> = ready_from_event(ev)
        sio.set_readiness(TICK_INC, ready.bits)
        wakes<WakeList> = sio.wake(ready)
        // The reactor surfaces ctx_packed values to its caller; the
        // current first-pass impl drops them here because the scheduler
        // glue layer (task 11.x) has not landed yet. Once the runtime
        // root is ready, hand wakes back to the scheduler instead.
        wakes.wake_by_ref()
        fired += 1
    }

    if fired > 0 {
        m<Metrics> = handle.metrics
        m.incr_ready_count_by(fired)
    }
    return 0
}

// Drop pending wakes without scheduling. Used during reactor shutdown
// once the scheduler is gone.
WakeList::wake_by_ref(){
    this.len = 0
}

