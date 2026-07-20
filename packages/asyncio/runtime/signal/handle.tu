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

// Last EventInfo from register — dual-ret (i32, EventInfo) drops the
// mem across packages (same trap as IoDriver / SignalDriver factories).
LAST_EVENTINFO<EventInfo> = null

fn eventinfo_last() EventInfo {
    return LAST_EVENTINFO
}

// Register the calling thread's interest in `signum`. Returns 0 on success
// and publishes EventInfo via eventinfo_last(); else RT_SIG_NOT_REG / Other.
SignalDriverHandle::register(signum<i32>) i32 {
    LAST_EVENTINFO = null
    if signum < 1 return RT_SIG_NOT_REG
    if signum >= NUM_SIGNALS return RT_SIG_NOT_REG
    if signum == SIGKILL_SIGNUM return RT_SIG_NOT_REG
    if signum == SIGSTOP_SIGNUM return RT_SIG_NOT_REG

    if this.gslot_bits == 0 return RT_SIG_NOT_REG
    gref<SignalGlobals> = null
    gref = this.gslot_bits
    ev<EventInfo>    = signal_globals_event(gref, signum)
    if ev == null return RT_SIG_NOT_REG

    // Block the signal in the process mask so it queues into signalfd
    // instead of being delivered to a thread handler.
    mask<u64> = 0
    std.sigemptyset(&mask)
    std.sigaddset(&mask, signum)
    rerr<i32> = 0
    mask_p<u64*> = &mask
    how_block<i32> = std.SIG_BLOCK
    old_none<u64> = 0
    szmask_pm<u64> = 8
    std.rt_sigprocmask(how_block, mask_p.(u64), old_none, szmask_pm)

    // Re-arm the signalfd with the widened set. Read the current mask
    // first; on first registration it's empty so the union is just `mask`.
    cur<u64> = 0
    cur_p<u64*> = &cur
    zero_set<u64> = 0
    std.rt_sigprocmask(how_block, zero_set, cur_p.(u64), szmask_pm)
    // Locals for signalfd4 args (literal sizemask/flags corrupt syscall ABI).
    szmask<u64> = 8
    sfd_flags<i32> = std.SFD_CLOEXEC | std.SFD_NONBLOCK
    cur_fd<i32> = gref.sfd
    fd<i32> = std.signalfd4(cur_fd, cur_p.(u64), szmask, sfd_flags)
    if fd < 0 return io.Other
    gref.sfd = fd

    LAST_EVENTINFO = ev
    return 0
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

