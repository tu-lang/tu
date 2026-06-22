// Strong-side Runtime owner. shutdown_*  calls are idempotent and
// release the held drivers + blocking pool. Runtime::handle returns a
// weak Handle suitable for cloning across threads.

use asyncio.task

KIND_CURRENT_THREAD<i32> = 0
KIND_MULTI_THREAD<i32>   = 1

// Strong owner of every long-lived runtime resource.
mem Runtime {
    i32           kind
    Handle*       weak_handle
    DriverHandle* driver_handle
    Driver*       driver
    Spawner*      blocking_spawner
    BlockingPool* blocking_pool
    u64           scheduler_handle    // raw bits of CtHandle* / MtHandle*
    i32           shutdown_state      // 0 = running, 1 = shutting down, 2 = done
}

// Build a Runtime from already-composed pieces. Builder::build does the
// composition; this constructor is package-internal.
const Runtime::compose(
    kind<i32>,
    weak<Handle>,
    drv<Driver>,
    drv_h<DriverHandle>,
    sp<Spawner>,
    pool<BlockingPool>,
    sched<u64>
) Runtime {
    r<Runtime> = new Runtime
    r.kind             = kind
    r.weak_handle      = weak
    r.driver           = drv
    r.driver_handle    = drv_h
    r.blocking_spawner = sp
    r.blocking_pool    = pool
    r.scheduler_handle = sched
    r.shutdown_state   = 0
    return r
}

// Cheap weak handle clone.
Runtime::handle() Handle {
    return this.weak_handle
}

// Run fut to completion. multi_thread routes through a current_thread
// driver since block_on is inherently single-threaded.
Runtime::block_on(fut) (i32, i64) {
    if this.kind == KIND_CURRENT_THREAD {
        ct<CtHandle> = this.scheduler_handle.(CtHandle)
        return block_on(ct, fut)
    }
    return this.weak_handle.block_on(fut)
}

// Spawn a future via the active scheduler.
Runtime::spawn(fut) JoinHandle {
    return this.weak_handle.spawn(fut)
}

// Spawn a blocking closure.
Runtime::spawn_blocking(op<fc<blocking_op>>) JoinHandle {
    return this.weak_handle.spawn_blocking(op)
}

// Shutdown with a deadline; idempotent. First call closes the inject
// queues, signals shutdown to the blocking pool, and tears down the
// driver. Second call is a no-op so safe to invoke from Drop-like sites.
Runtime::shutdown_timeout(d<sys.Duration>){
    if this.shutdown_state == 2 return
    this.shutdown_state = 1
    if this.kind == KIND_CURRENT_THREAD {
        ct<CtHandle> = this.scheduler_handle.(CtHandle)
        ct.shared.inject.close()
    } else {
        mh<MtHandle> = this.scheduler_handle.(MtHandle)
        mh.shared.inject.close()
    }
    if this.blocking_pool != null this.blocking_pool.shutdown()
    if this.driver != null this.driver.shutdown(this.driver_handle)
    this.shutdown_state = 2
}

// Background variant: shutdown without a hard deadline. Same semantics.
Runtime::shutdown_background(){
    if this.shutdown_state == 2 return
    this.shutdown_state = 1
    if this.kind == KIND_CURRENT_THREAD {
        ct<CtHandle> = this.scheduler_handle.(CtHandle)
        ct.shared.inject.close()
    } else {
        mh<MtHandle> = this.scheduler_handle.(MtHandle)
        mh.shared.inject.close()
    }
    if this.blocking_pool != null this.blocking_pool.shutdown()
    if this.driver != null this.driver.shutdown(this.driver_handle)
    this.shutdown_state = 2
}

