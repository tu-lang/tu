// Read-only hang diagnostics for IoHandle registrations.
// Walks the live ScheduledIo chain under synced_lock.

use fmt
use runtime
use std.atomic

// Dump every live ScheduledIo: readiness word, reader/writer ctx, iosrc.
fn io_debug_dump(ioh_bits<u64>) {
    if ioh_bits == 0 {
        fmt.println("io_debug: null ioh")
        return
    }
    ih<IoHandle> = ioh_bits.(IoHandle)
    if ih == null || ih.synced == null || ih.synced_lock == null {
        fmt.println("io_debug: incomplete handle")
        return
    }
    lk<runtime.MutexInter> = ih.synced_lock
    lk.lock()
    live<u32> = ih.synced.live_count
    pending<u32> = ih.synced.pending_count
    fmt.println("io_debug: live=", int(live), " pending=", int(pending),
        " shutdown=", int(ih.synced.is_shutdown))
    cur<ScheduledIo> = ih.synced.head
    n<i32> = 0
    while cur != null && n < 64 {
        ready_w<u64> = atomic.load64(&cur.readiness)
        ready_bits<i32> = unpack_ready_bits(ready_w)
        tick<i32> = unpack_tick(ready_w)
        shut<i32> = unpack_shutdown(ready_w)
        fmt.println("  sio[", int(n), "] ready=", int(ready_bits),
            " tick=", int(tick),
            " shut=", int(shut),
            " rctx=", int(cur.reader_ctx),
            " wctx=", int(cur.writer_ctx),
            " iosrc=", int(cur.iosrc_bits),
            " queued=", int(cur.release_queued))
        cur = cur.next_sio
        n += 1
    }
    lk.unlock()
}
