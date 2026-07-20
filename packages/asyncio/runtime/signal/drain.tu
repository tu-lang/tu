// Drain signalfd into EventInfo::fire (mother: signal Driver::process).

use std
use sys
use asyncio.sync as libsync

SIGINFO_BYTES<u64> = 128
DRAIN_WOULD_BLOCK<i32> = 16908302

fn signal_driver_drain(drv<SignalDriver>) {
    if drv == null return
    slot<u64> = 0
    slot = drv.gslot_bits
    if slot == 0 return
    glob_ref<SignalGlobals> = null
    glob_ref = slot
    drain_fd<i32> = globals_sfd(glob_ref)
    if drain_fd < 0 return
    nbytes<u64> = SIGINFO_BYTES
    buf<u8*> = std.malloc(nbytes)
    if buf == null return
    loop {
        raw<i64> = sys.read(drain_fd, buf, nbytes)
        cerr<i32>, nread<u64> = sys.cvt(raw)
        if cerr == DRAIN_WOULD_BLOCK break
        if cerr != 0 break
        if nread == 0 break
        signo_p<u32*> = buf.(u64)
        signum_u<u32> = *signo_p
        signum<i32> = 0
        signum = signum_u
        ev<EventInfo> = signal_globals_event(glob_ref, signum)
        if ev != null {
            ev.fired_count += 1
            nbits<u64> = ev.notify_bits
            if nbits != 0 {
                libsync.notify_waiters_raw(nbits)
            }
        }
    }
}
