// multi_thread block_on. Matches multi_thread/mod.rs:
// CachedParkThread::block_on — poll the root on the calling thread only;
// spawned tasks run on the worker pool. When the root is woken, schedule
// unparks this thread and does not push the root onto inject.

use runtime
use asyncio.task

fn mt_block_on_task_ctx(t<task.RawTask>) u64 {
    return t.(u64)
}

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

// CachedParkThread::block_on stand-in: poll root / park until COMPLETE.
// Each direct poll must own a Notified ref (prepare_direct_poll); park
// alone can return on eventfd without wake_by_ref.
fn mt_block_on(handle<MtHandle>, fut) i32, i64 {
    fut_bits<u64> = 0
    fut_bits = fut
    root<task.RawTask> = task.bind_root(
        fut_bits,
        handle,
        mt_schedule_bridge.(u64),
        mt_release_bridge.(u64)
    )

    shared<MtShared> = handle.shared
    park<Parker> = Parker::new(shared.park_hub)
    up<Unparker> = Unparker::new(park)
    shared.block_on_unparker = up
    root_bits<u64> = 0
    root_bits = root
    shared.block_on_root_bits = root_bits

    err_out<i32> = 0
    val_out<i64> = 0
    root_ctx<u64> = mt_block_on_task_ctx(root)

    loop {
        snap<i32> = root.life_load()
        if (snap & task.COMPLETE) != 0 {
            err_out = 0
            val_out = root.task_cell.peek_output()
            break
        }

        if shared.inject.is_closed() {
            err_out = 0x03020005 // asyncio.error.RuntimeShutdown
            break
        }

        task.raw_prepare_direct_poll(root)
        task.harness_poll(root, root_ctx)

        snap2<i32> = root.life_load()
        if (snap2 & task.COMPLETE) != 0 {
            err_out = 0
            val_out = root.task_cell.peek_output()
            break
        }

        mt_park_block_on(park, shared)
        runtime.osyield()
    }

    shared.block_on_root_bits = 0
    shared.block_on_unparker = null
    return err_out, val_out
}
