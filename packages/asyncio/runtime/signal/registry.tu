// Process-wide signal registry. One EventInfo per signum holds the list
// of subscribers; SignalGlobals is a singleton allocated on first
// SignalDriver::new and looked up from the syscall handler.

use std
use util
use sync

// Linux supports up to 64 RT/standard signals (signum 1..63).
NUM_SIGNALS<i32> = 64

// Per-signum bookkeeping: a Notify so subscribers can listen for the
// "fired" edge and a counter the driver bumps on every observation.
mem EventInfo {
    i32          signum
    sync.Notify* notify
    u64          fired_count   // monotonic; subscribers compare their last seen to detect new events
}

// Build a fresh EventInfo for signum.
const EventInfo::new(signum<i32>) EventInfo* {
    e<EventInfo> = new EventInfo
    e.signum      = signum
    e.notify      = sync.Notify::new()
    e.fired_count = 0
    return &e
}

// Process-global registry. events[i] is null until something registers
// for signum i; use signal_globals_get_or_init to grab the singleton.
mem SignalGlobals {
    i32         signal_fd     // signalfd descriptor; <0 = uninitialised
    u64*        events        // raw bits of EventInfo*; sized NUM_SIGNALS slots
}

// Lazy singleton. Module-level pointer + Once-style guard.
G_SIGNAL_GLOBALS<SignalGlobals*> = null
G_SIGNAL_INIT<util.OnceCell*>    = null

// Build the singleton if missing and return it. Idempotent.
fn signal_globals_get_or_init() (i32, SignalGlobals*) {
    if G_SIGNAL_GLOBALS != null return 0, G_SIGNAL_GLOBALS

    g<SignalGlobals> = new SignalGlobals
    g.signal_fd = -1
    g.events    = std.malloc(sizeof(u64) * NUM_SIGNALS.(u64))
    for i<i32> = 0 ; i < NUM_SIGNALS ; i += 1 {
        g.events[i] = 0
    }
    G_SIGNAL_GLOBALS = &g
    return 0, &g
}

// Look up (or allocate) the EventInfo for signum.
fn signal_globals_event(g<SignalGlobals>, signum<i32>) EventInfo* {
    if signum < 1 return null
    if signum >= NUM_SIGNALS return null
    bits<u64> = g.events[signum]
    if bits != 0 return bits.(EventInfo)
    e<EventInfo> = EventInfo::new(signum)
    g.events[signum] = e.(u64)
    return &e
}

// Snapshot fired_count without taking the Notify lock.
EventInfo::fired_count_snapshot() u64 {
    return this.fired_count
}

// Increment fired_count and wake every waiter currently parked on notify.
// Called by SignalDriver::process when read(signalfd) returns siginfo.
EventInfo::fire(){
    this.fired_count += 1
    this.notify.notify_waiters()
}

