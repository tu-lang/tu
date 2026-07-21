// SIGCHLD reaper (tokio orphan/child reaping fallback).
//
// Design note (task 17.2): subscribes to SIGCHLD through the signal driver and
// reaps exited children with waitpid(WNOHANG). V1: the signal-driven wakeup
// loop (await SIGCHLD notification -> sweep) is not wired to a running IO
// driver, so reap_pending() is exposed as a manual sweep and reap_loop() does
// a single subscribe + sweep.

use runtime
use io
use std
use os
use asyncio.runtime.signal as rtsig

// Reaper holding the signal driver handle used to subscribe to SIGCHLD.
mem SigchldReaper {
    rtsig.SignalDriverHandle* sig
}

// Build a reaper bound to `sig` (may be null when no signal driver is active).
const SigchldReaper::new(sig<rtsig.SignalDriverHandle>) SigchldReaper {
    return new SigchldReaper { sig: sig }
}

// Subscribe to SIGCHLD so the kernel queues it for the signal driver. Returns
// the register result (io.Ok on success); a null handle is a no-op success.
SigchldReaper::start() i32 {
    if this.sig == null return io.Ok
    err<i32> = this.sig.register(os.SIGCHLD)
    return err
}

// Reap every already-exited child (waitpid(-1, WNOHANG)) without blocking.
// Returns the number of children reaped; stops at 0 (none ready) or <0
// (no remaining children).
SigchldReaper::reap_pending() i32 {
    n<i32> = 0
    loop {
        status<i32> = 0
        r<i32> = std.waitpid(-1, waitpid_status_addr(&status), std.WNOHANG)
        if r <= 0 break
        n += 1
    }
    return n
}

// Reaper task body. V1: subscribe then sweep once (sync). Mother loops on
// SIGCHLD notifications; continuous await lands when the signal driver is wired.
SigchldReaper::reap_loop() i32 {
    serr<i32> = this.start()
    if serr != io.Ok return serr
    this.reap_pending()
    return io.Ok
}
