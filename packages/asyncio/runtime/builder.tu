// Runtime builder. Mirrors tokio::runtime::Builder so user code can
// dial in worker count, IO/time toggles, and queue depths without
// touching the runtime internals directly.

use asyncio.error as aerr
use asyncio.runtime.io as rtio
use asyncio.runtime.time as rttime
use asyncio.runtime.signal as rtsig
use asyncio.runtime.blocking as rtblk
use asyncio.runtime.scheduler as sched
use asyncio.util

// Default cap for the blocking pool.
DEFAULT_MAX_BLOCKING_THREADS<u32> = 512

// Build-time configuration. kind chooses current_thread vs multi_thread;
// build() routes accordingly.
mem Builder {
    i32   kind                    // 0 = current_thread, 1 = multi_thread
    i32   enable_io
    i32   enable_time
    u32   worker_threads
    u32   max_blocking_threads
    u64   thread_stack_size       // 0 = default
    u32   event_interval
    u32   global_queue_interval
    i32   disable_lifo_slot
    u64   clock_slot              // optional rttime.Clock heap pointer; 0 = none
}

// Build a current_thread builder with sane defaults.
const Builder::new_current_thread() Builder {
    b<Builder> = new Builder
    b.kind                  = KIND_CURRENT_THREAD
    b.enable_io             = 0
    b.enable_time           = 0
    b.worker_threads        = 1
    b.max_blocking_threads  = DEFAULT_MAX_BLOCKING_THREADS
    b.thread_stack_size     = 0
    b.event_interval        = DEFAULT_EVENT_INTERVAL
    b.global_queue_interval = DEFAULT_GLOBAL_QUEUE_INTERVAL
    b.disable_lifo_slot     = 0
    b.clock_slot            = 0
    return b
}

// Build a multi_thread builder. worker_threads defaults to 1; user
// should call worker_threads(n) before build.
const Builder::new_multi_thread() Builder {
    b<Builder> = Builder::new_current_thread()
    b.kind = KIND_MULTI_THREAD
    return b
}

// Setters return Builder so calls chain.
Builder::worker_threads(n<u32>) Builder {
    this.worker_threads = n
    return this
}
Builder::max_blocking_threads(n<u32>) Builder {
    this.max_blocking_threads = n
    return this
}
Builder::thread_stack_size(n<u64>) Builder {
    this.thread_stack_size = n
    return this
}
Builder::enable_io() Builder {
    this.enable_io = 1
    return this
}
Builder::enable_time() Builder {
    this.enable_time = 1
    return this
}
Builder::enable_all() Builder {
    this.enable_io = 1
    this.enable_time = 1
    return this
}
Builder::event_interval(n<u32>) Builder {
    this.event_interval = n
    return this
}
Builder::global_queue_interval(n<u32>) Builder {
    this.global_queue_interval = n
    return this
}
Builder::disable_lifo_slot_set() Builder {
    this.disable_lifo_slot = 1
    return this
}

// Compose IO + time + signal drivers based on enable_* flags. Returns
// a (Driver, DriverHandle) pair plus an optional error code.
fn build_drivers(b<Builder>) (i32, Driver, DriverHandle) {
    io_drv<rtio.IoDriver>    = null
    io_h<rtio.IoHandle>      = null
    time_drv<rttime.TimeDriver> = null
    time_h<rttime.TimeHandle>   = null
    sig_drv<rtsig.SignalDriver> = null
    sig_h<rtsig.SignalDriverHandle> = null

    if b.enable_io == 1 {
        ierr<i32>, iod<rtio.IoDriver>, ioh<rtio.IoHandle> = rtio.IoDriver::new()
        if ierr != 0 return ierr, null, null
        io_drv = iod
        io_h   = ioh

        // Signal driver lives on top of the IO driver.
        serr<i32>, sd<rtsig.SignalDriver>, sh<rtsig.SignalDriverHandle> = rtsig.SignalDriver::new(ioh.(u64))
        if serr == 0 {
            sig_drv = sd
            sig_h   = sh
        }
    }

    if b.enable_time == 1 {
        td<rttime.TimeDriver>, th<rttime.TimeHandle> = rttime.TimeDriver::new(io_drv)
        time_drv = td
        time_h   = th
    }

    drv<Driver>, drv_h<DriverHandle> = Driver::compose(io_drv, io_h, time_drv, time_h, sig_drv, sig_h)
    return 0, drv, drv_h
}

// Build a current_thread runtime: shared scheduler + blocking pool +
// optional drivers + a Handle wired to all of the above.
fn build_current_thread(b<Builder>) (i32, Runtime) {
    err<i32>, drv<Driver>, drv_h<DriverHandle> = build_drivers(b)
    if err != 0 return err, null

    pool<rtblk.BlockingPool> = rtblk.BlockingPool::new(b.max_blocking_threads)
    spawner<rtblk.Spawner>   = rtblk.Spawner::new(pool)

    shared<sched.CtShared>   = sched.CtShared::new()
    shared.driver_handle    = drv_h.(u64)
    shared.blocking_spawner = spawner.(u64)
    handle<sched.CtHandle>   = sched.CtHandle::new(shared)

    weak<Handle> = Handle::new(handle.(u64), KIND_CURRENT_THREAD, drv_h, spawner.(u64))
    return 0, Runtime::compose(KIND_CURRENT_THREAD, weak, drv, drv_h, spawner, pool, handle.(u64))
}

// Build a multi_thread runtime: shared MtShared + N workers spawned via
// runtime.newcore(worker_entry).
// queue_local() / Steal / Local return heap pointers; assign through
// without wrapping with `&`.
fn build_multi_thread(b<Builder>) (i32, Runtime) {
    err<i32>, drv<Driver>, drv_h<DriverHandle> = build_drivers(b)
    if err != 0 return err, null

    pool<rtblk.BlockingPool> = rtblk.BlockingPool::new(b.max_blocking_threads)
    spawner<rtblk.Spawner>   = rtblk.Spawner::new(pool)

    shared<sched.MtShared>   = sched.MtShared::new(b.worker_threads)
    handle<sched.MtHandle>   = sched.MtHandle::new(shared)
    handle.driver_handle    = drv_h.(u64)
    handle.blocking_spawner = spawner.(u64)

    for i<u32> = 0 ; i < b.worker_threads ; i += 1 {
        steal_a<sched.Steal>, local_b<sched.Local> = sched.queue_local()
        rng<util.FastRand>     = util.FastRand::new(0xdeadbeef + i.(u64))
        park<sched.Parker>      = sched.Parker::new(drv_h.(u64))
        unparker<sched.Unparker> = sched.Unparker::new(park)
        core<sched.WorkerCore>  = sched.WorkerCore::new(local_b, park, rng, b.global_queue_interval)
        worker<sched.MtWorker>  = sched.MtWorker::new(handle, i, core)

        r<sched.Remote> = new sched.Remote
        r.steal_end = steal_a
        r.unparker = unparker
        shared.remotes[i] = r.(u64)

        ACTIVE_WORKER = worker
        runtime.newcore(sched.worker_entry.(u64))
    }

    weak<Handle> = Handle::new(handle.(u64), KIND_MULTI_THREAD, drv_h, spawner.(u64))
    return 0, Runtime::compose(KIND_MULTI_THREAD, weak, drv, drv_h, spawner, pool, handle.(u64))
}

// Top-level entry: validates kind and dispatches.
Builder::build() (i32, Runtime) {
    if this.kind == KIND_MULTI_THREAD return build_multi_thread(this)
    return build_current_thread(this)
}

