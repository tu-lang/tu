// Bridges signalfd(2) into the IO driver. SignalDriver::new opens the
// signalfd, registers it with the IO driver via TOKEN_SIGNAL, and lets
// the dispatcher in IoDriver::turn flag this.signal_ready when an event
// arrives. process() is invoked from the runtime root after every IO
// turn to drain the signalfd and fan signals out to subscribers.
//
// Mother: tokio::runtime::signal::Driver (pipe + broadcast). Tu V1 uses
// signalfd per design §15 — same park → process → fan-out shape.

use runtime
use std
use io
use sys
use asyncio.runtime.io as rtio

// Driver-side state. park_iod_bits / park_ioh_bits back-edges into the IO
// driver so process() can consume_signal_ready and new() can register the fd.
// Not named io_* — `.io_handle` / `.iod_bits` are type-assert traps.
mem SignalDriver {
    i32                reg_fd        // signalfd descriptor
    u64                reg_sio       // unused; reserved for ScheduledIo wiring
    u64                gslot_bits    // SignalGlobals* as u64 (avoid .globals/.gslot traps)
    runtime.MutexInter* lock
    u64                park_iod_bits // IoDriver* bits for consume_signal_ready
    u64                park_ioh_bits // IoHandle* bits for register_sfd
}

// Cross-call-face handle backing the signal-subscription API.
mem SignalDriverHandle {
    u64            gslot_bits  // SignalGlobals* as u64
    u64            lock_bits   // MutexInter* bits for cross-pkg lock/unlock
}

// Last successful SignalDriver::new results. build_drivers uses
// signaldriver_last / signalhandle_last — (i32, mem, mem) triple-ret drops
// the handle (same trap as IoDriver::new / make_poll).
LAST_SIGDRIVER<SignalDriver> = null
LAST_SIGHANDLE<SignalDriverHandle> = null

fn signaldriver_last() SignalDriver {
    return LAST_SIGDRIVER
}
fn signalhandle_last() SignalDriverHandle {
    return LAST_SIGHANDLE
}

// sizeof(signalfd_siginfo) on Linux.
SIGINFO_LEN<u64> = 128
// io.WouldBlock — local copy avoids short-name clash in this package.
SIG_WOULD_BLOCK<i32> = 16908302

// Initialise globals + open the signalfd with an empty mask, register it
// on the IO driver as TOKEN_SIGNAL. Publishes via last() getters.
// Mother: runtime::signal::Driver::new + register_signal_receiver.
const SignalDriver::new(iod_bits<u64>, ioh_bits<u64>) i32 {
    LAST_SIGDRIVER = null
    LAST_SIGHANDLE = null

    err<i32>, g<SignalGlobals> = signal_globals_get_or_init()
    if err != 0 return err

    mask<u64> = 0
    mask_ptr<u64*> = &mask
    mask_bits<u64> = mask_ptr.(u64)
    // Locals for every signalfd4 arg — literal -1 / 8 corrupt in syscall ABI
    // (same trap as process dup2/kill 2nd arg).
    fd_in<i32> = -1
    szmask<u64> = 8
    sfd_flags<i32> = std.SFD_CLOEXEC | std.SFD_NONBLOCK
    fd<i32> = std.signalfd4(fd_in, mask_bits, szmask, sfd_flags)
    if fd < 0 return io.Other

    g.sfd = fd

    // Mother: io_handle.register_signal_receiver — epoll ADD TOKEN_SIGNAL.
    // register_sfd returns sys.Ok (=1) on success (netio Selector convention).
    if ioh_bits != 0 {
        ioh<rtio.IoHandle> = null
        ioh = ioh_bits
        rerr<i32> = ioh.register_sfd(fd)
        ok_sel<i32> = 1
        if rerr != 0 {
            if rerr != ok_sel return rerr
        }
    }

    drv<SignalDriver> = new SignalDriver
    drv.reg_fd    = fd
    drv.reg_sio   = 0
    gbits<u64> = 0
    gbits = g
    drv.gslot_bits = gbits
    drv.lock = new runtime.MutexInter
    drv.lock.init()
    drv.park_iod_bits = iod_bits
    drv.park_ioh_bits = ioh_bits

    h<SignalDriverHandle> = new SignalDriverHandle
    h.gslot_bits = gbits
    lk<runtime.MutexInter> = drv.lock
    h.lock_bits = lk.(u64)

    LAST_SIGDRIVER = drv
    LAST_SIGHANDLE = h
    return 0
}

// Drain the signalfd. Mother: park → process after consume_signal_ready.
// V1: always attempt drain (nonblock). EPOLLET + padded token mismatch can
// skip consume_signal_ready; skipping drain then hangs forever.
SignalDriver::process(){
    if this.park_iod_bits != 0 {
        rtio.iodriver_consume_signal_ready_bits(this.park_iod_bits)
    }
    signal_driver_drain(this)
}

// Cross-pkg park hook — Driver cannot reliably member-call process().
fn signal_driver_process_bits(drv_bits<u64>) {
    if drv_bits == 0 return
    drv<SignalDriver> = null
    drv = drv_bits
    if drv.park_iod_bits != 0 {
        rtio.iodriver_consume_signal_ready_bits(drv.park_iod_bits)
    }
    signal_driver_drain(drv)
}

// Tear down: close the signalfd. The runtime root drives this on shutdown.
SignalDriver::shutdown(){
    if this.gslot_bits == 0 return
    gref<SignalGlobals> = null
    gref = this.gslot_bits
    if gref.sfd < 0 return
    sys.close(gref.sfd)
    gref.sfd = -1
    this.reg_fd = -1
}

// Cross-pkg shutdown — aggregate Driver must not member-call SignalDriver.
fn signal_driver_shutdown_bits(drv_bits<u64>) {
    if drv_bits == 0 return
    drv<SignalDriver> = null
    drv = drv_bits
    if drv.gslot_bits == 0 return
    gref<SignalGlobals> = null
    gref = drv.gslot_bits
    if gref.sfd < 0 return
    sys.close(gref.sfd)
    gref.sfd = -1
    drv.reg_fd = -1
}

fn sg_bits_of(drv<SignalDriver>) u64 {
    if drv == null return 0
    return drv.gslot_bits
}
