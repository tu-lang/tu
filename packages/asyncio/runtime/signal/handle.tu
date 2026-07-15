// User-facing entry to the signal driver. Subscribers call register(sig)
// to widen the process signal mask and obtain an EventInfo they can
// poll. First call for each signum installs a "ignore" handler so the
// kernel queues the signal for signalfd to deliver instead of running a
// default action.

use runtime
use std
use io
// SIGKILL / SIGSTOP cannot be intercepted; reject early.
SIGKILL_SIGNUM<i32> = 9
SIGSTOP_SIGNUM<i32> = 19

// asyncio.runtime.error.RT_SIG_NOT_REG (asmgen local)
RT_SIG_NOT_REG<i32> = 0x0302000F

// Register the calling thread's interest in `signum`. Returns
//   0           — registered successfully; *out is filled with EventInfo*
//   SignalNotRegistered — signum out of range or unsupported
//   Other       — sigprocmask / signalfd4 syscall failure
SignalDriverHandle::register(signum<i32>) i32, EventInfo {
    if signum < 1 return RT_SIG_NOT_REG, null
    if signum >= NUM_SIGNALS return RT_SIG_NOT_REG, null
    if signum == SIGKILL_SIGNUM return RT_SIG_NOT_REG, null
    if signum == SIGSTOP_SIGNUM return RT_SIG_NOT_REG, null

    g<SignalGlobals> = this.globals
    ev<EventInfo>    = signal_globals_event(g, signum)
    if ev == null return RT_SIG_NOT_REG, null

    // Block the signal in the process mask so it queues into signalfd
    // instead of being delivered to a thread handler.
    mask<u64> = 0
    std.sigemptyset(&mask)
    std.sigaddset(&mask, signum)
    rerr<i32> = 0
    mask_p<u64*> = &mask
    std.rt_sigprocmask(std.SIG_BLOCK, mask_p.(u64), 0, 8)

    // Re-arm the signalfd with the widened set. Read the current mask
    // first; on first registration it's empty so the union is just `mask`.
    cur<u64> = 0
    cur_p<u64*> = &cur
    std.rt_sigprocmask(std.SIG_BLOCK, 0, cur_p.(u64), 8)
    fd<i32> = std.signalfd4(g.signal_fd, cur_p.(u64), 8, std.SFD_CLOEXEC | std.SFD_NONBLOCK)
    if fd < 0 return io.Other, null
    g.signal_fd = fd

    return 0, ev
}

// Unsubscribe `signum`. We unblock the signal so the default handler
// fires again. The Notify slot stays alive for any other subscribers.
SignalDriverHandle::unregister(signum<i32>) i32 {
    if signum < 1 return RT_SIG_NOT_REG
    if signum >= NUM_SIGNALS return RT_SIG_NOT_REG

    mask<u64> = 0
    std.sigaddset(&mask, signum)
    mask_p<u64*> = &mask
    std.rt_sigprocmask(std.SIG_UNBLOCK, mask_p.(u64), 0, 8)
    return 0
}

