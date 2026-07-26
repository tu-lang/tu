// Drain signalfd into EventInfo fired_count.
// Returns 1 if at least one siginfo was applied (caller should unpark).

use std
use sys
use asyncio.util as util

SIGINFO_BYTES<u64> = 128

fn signal_driver_drain(drv<SignalDriver>) i32 {
    if drv == null { return 0 }
    slot<u64> = 0
    slot = drv.gslot_bits
    if slot == 0 { return 0 }
    glob_ref<SignalGlobals> = null
    glob_ref = slot
    drain_fd<i32> = globals_sfd(glob_ref)
    if drain_fd < 0 { return 0 }
    nbytes<u64> = SIGINFO_BYTES
    buf<u8*> = std.malloc(nbytes)
    if buf == null { return 0 }
    fired_any<i32> = 0
    loop {
        // Prefer raw < 0 over sys.cvt(i64→i32) which can drop success paths.
        raw<i64> = sys.read(drain_fd, buf, nbytes)
        if raw < 0 {
            break
        }
        if raw == 0 {
            break
        }
        signum_u<u32> = 0
        std.memcpy(&signum_u, buf, 4)
        signum<i32> = 0
        signum = signum_u
        if signum >= 1 {
            if signum < NUM_SIGNALS {
                ev<EventInfo> = signal_globals_event(glob_ref, signum)
                if ev != null {
                    // Bump + wake Notify waiters.
                    ev.fire()
                }
            }
        }
        util.signal_deliveries_bump()
        fired_any = 1
    }
    if fired_any != 0 {
        drv.park_skip = 1
    }
    return fired_any
}
