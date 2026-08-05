// multi_thread block_on. Mother: runtime/park.rs CachedParkThread::block_on
// + multi_thread/mod.rs enter_runtime → blocking.block_on(future).
//
// Polls the user future directly with an UnparkThread-style waker (tagged
// Unparker* bits). Spawned tasks run on workers. No RawTask / harness for
// the block_on root — that Notified refcount path is CT-only.

use runtime
use sys
use asyncio.task
use asyncio.error as aerr
use asyncio.runtime as asyncrt

fn mt_block_on_raw(bits<u64>, fut) i32, i64 {
    mh<MtHandle> = bits.(MtHandle)
    err<i32> = 0
    val<i64> = 0
    err, val = mt_block_on(mh, fut)
    return err, val
}

fn mt_block_on_bits(handle_bits<u64>, fut_bits<u64>) i32, i64 {
    mh<MtHandle> = handle_bits.(MtHandle)
    fut<runtime.Future> = fut_bits.(runtime.Future)
    err<i32> = 0
    val<i64> = 0
    err, val = mt_block_on(mh, fut)
    return err, val
}

// Unparker bits for empty-IO wake nudge (driver → block_on park).
MT_BLOCK_ON_UP_BITS<u64> = 0

fn mt_empty_io_nudge() i32 {
    bits<u64> = MT_BLOCK_ON_UP_BITS
    if bits == 0 {
        return 0
    }
    up<Unparker> = bits.(Unparker)
    if up == null {
        return 0
    }
    up.unpark()
    return 0
}

// CachedParkThread::block_on — poll / park until Ready.
fn mt_block_on(handle<MtHandle>, fut) i32, i64 {
    shared<MtShared> = handle.shared
    park<Parker> = Parker::new(shared.park_hub)
    up<Unparker> = Unparker::new(park)
    shared.block_on_unparker = up
    MT_BLOCK_ON_UP_BITS = up.(u64)
    // No RawTask root (mother polls a plain Future).
    shared.block_on_root_bits = 0

    task.install_block_on_wake_hook(mt_block_on_wake_tagged.(u64))
    task.install_empty_io_nudge_hook(mt_empty_io_nudge.(u64))
    // Mother UnparkThread waker: low bit tags Unparker* so wake_by_ctx
    // unparks instead of RawTask::wake_by_ref.
    waker_ctx<u64> = task.block_on_waker_tag(up.(u64))

    err_out<i32> = 0
    val_out<i64> = 0
    f<runtime.Future> = fut
    ran_since_turn<u32> = 0
    ev_i<u32> = 61
    if shared.event_interval != 0.(u32) {
        ev_i = shared.event_interval
    }

    loop {
        if shared.inject.is_closed() {
            err_out = aerr.RuntimeShutdown
            break
        }

        // Mother / CT: periodic non-blocking driver turn so IO progresses
        // while block_on is busy polling Ready leaves (e.g. sequential accept).
        if ran_since_turn >= ev_i {
            zero<sys.Duration> = sys.Duration::from_millis(0)
            park.park_timeout(handle.driver_handle, zero)
            ran_since_turn = 0
        }

        // Mother wraps each task poll in coop::budget; block_on root is
        // not a RawTask, so reset here before each leaf poll_proceed.
        asyncrt.reset_budget()

        prev_ctx<u64> = task.poll_ctx_set(waker_ctx)
        ready<i32>, output<i64> = f.poll()
        task.poll_ctx_set(prev_ctx)
        ran_since_turn += 1

        if ready == runtime.PollReady {
            err_out = 0
            val_out = output
            break
        }

        mt_park_block_on(park, shared)
        ran_since_turn = 0
    }

    shared.block_on_unparker = null
    MT_BLOCK_ON_UP_BITS = 0
    return err_out, val_out
}

// wake_by_ctx hook: tagged ctx → Unparker::unpark (mother wake_by_ref).
fn mt_block_on_wake_tagged(ctx_tagged<u64>) i32 {
    up_bits<u64> = task.block_on_waker_untag(ctx_tagged)
    if up_bits == 0 {
        return 0
    }
    up<Unparker> = up_bits.(Unparker)
    if up == null {
        return 0
    }
    up.unpark()
    return 0
}
