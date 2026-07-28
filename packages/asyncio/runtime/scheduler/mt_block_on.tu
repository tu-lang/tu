// multi_thread block_on. V1: poll root on the calling thread and drain
// inject for spawn traffic while block_on_exclusive is set. Parks via
// Parker/Note; schedule unparks via MtShared.block_on_unparker.
//
// Mother uses CachedParkThread only (workers own inject). Enabling that
// path currently hits worker Note/futex SEGV under N>1; see optimize debt.

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
    park<Parker> = Parker::new(0)
    up<Unparker> = Unparker::new(park)
    shared.block_on_unparker = up
    root_bits<u64> = 0
    root_bits = root
    shared.block_on_root_bits = root_bits
    shared.block_on_exclusive = 1

    err_out<i32> = 0
    val_out<i64> = 0
    inj<Inject> = shared.inject
    root_ctx<u64> = mt_block_on_task_ctx(root)

    loop {
        snap<i32> = root.life_load()
        if (snap & task.COMPLETE) != 0 {
            err_out = 0
            val_out = root.task_cell.peek_output()
            break
        }

        if inj.is_closed() {
            err_out = 0x03020005 // asyncio.error.RuntimeShutdown
            break
        }

        task.harness_poll(root, root_ctx)

        snap2<i32> = root.life_load()
        if (snap2 & task.COMPLETE) != 0 {
            err_out = 0
            val_out = root.task_cell.peek_output()
            break
        }

        did_work<i32> = 0
        if inj.is_empty() == 0 {
            ierr<i32>, ti<task.Notified> = inj.pop()
            if ierr == 0 {
                raw_t<task.RawTask> = ti.raw()
                // Never poll the block_on root from inject — caller owns it.
                if raw_t.(u64) != root_bits {
                    task.harness_poll(raw_t, mt_block_on_task_ctx(raw_t))
                    did_work = 1
                }
            }
        }

        if did_work == 0 {
            park.wait_until_wake(0)
        }
    }

    shared.block_on_exclusive = 0
    shared.block_on_root_bits = 0
    shared.block_on_unparker = null
    return err_out, val_out
}
