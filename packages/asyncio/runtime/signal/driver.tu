// Bridges signalfd(2) into the IO driver. SignalDriver::new opens the
// signalfd, registers it with the IO driver via TOKEN_SIGNAL, and lets
// the dispatcher in IoDriver::turn flag this.signal_ready when an event
// arrives. process() is invoked from the runtime root after every IO
// turn to drain the signalfd and fan signals out to subscribers.

use runtime
use std
use io

// Driver-side state. handle is a back-edge pointer (raw bits of
// IoHandle*) so process() can read events and SignalDriverHandle::register
// can call into the IO driver to update the signal mask without a
// circular import.
mem SignalDriver {
    i32                reg_fd        // signalfd descriptor
    u64                reg_sio       // raw bits of ScheduledIo*; null until task 11.x wires it
    SignalGlobals*     globals
    runtime.MutexInter lock
    u64                io_handle     // raw bits of IoHandle*; reserved for shutdown wiring
}

// Initialise globals + open the signalfd with an empty mask. Returns
// (err, driver, handle); err != 0 means the signalfd syscall failed.
const SignalDriver::new(io_handle_ptr<u64>) (i32, SignalDriver*, SignalDriverHandle*) {
    err<i32>, g<SignalGlobals> = signal_globals_get_or_init()
    if err != 0 return err, null, null

    mask<u64> = 0
    fd<i32>   = std.signalfd4(-1, mask.(u64*).(u64), 8, std.SFD_CLOEXEC | std.SFD_NONBLOCK)
    if fd < 0 return io.Other, null, null

    g.signal_fd = fd

    drv<SignalDriver> = new SignalDriver
    drv.reg_fd    = fd
    drv.reg_sio   = 0
    drv.globals   = g
    drv.lock.init()
    drv.io_handle = io_handle_ptr

    h<SignalDriverHandle> = new SignalDriverHandle
    h.globals = g
    h.lock_addr = &drv.lock.(u64)

    return 0, &drv, &h
}

// Drain the signalfd. Called by the runtime after IoDriver::turn flagged
// signal_ready. For each siginfo read, fan out via EventInfo::fire so
// subscribers' Notify wakes up.
SignalDriver::process(){
    g<SignalGlobals> = this.globals
    if g.signal_fd < 0 return

    si<std.SignalfdSiginfo> = new std.SignalfdSiginfo

    loop {
        // read(2) on signalfd returns one or more 128-byte records; we
        // call it in a loop until EAGAIN. Reads are non-blocking due to
        // SFD_NONBLOCK.
        size<u64> = sizeof(std.SignalfdSiginfo)
        n<i64>    = std.read(g.signal_fd, &si.(u8*), size)
        if n <= 0 break
        if n.(u64) < size break

        signum<i32> = si.ssi_signo.(i32)
        ev<EventInfo> = signal_globals_event(g, signum)
        if ev != null ev.fire()
    }
}

// Tear down: close the signalfd. The runtime root drives this on shutdown.
SignalDriver::shutdown(){
    g<SignalGlobals> = this.globals
    if g.signal_fd < 0 return
    std.close(g.signal_fd)
    g.signal_fd = -1
    this.reg_fd = -1
}

