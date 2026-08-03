// Runtime builder. Lets user code
// dial in worker count, IO/time toggles, and queue depths without
// touching the runtime internals directly.

use asyncio.error as aerr
use asyncio.runtime.io as rtio
use asyncio.runtime.time as rttime
use asyncio.runtime.signal as rtsig
use asyncio.runtime.blocking as rtblk
use asyncio.runtime.scheduler as sched
use asyncio.task as task
use asyncio.util

// Default cap for the blocking pool.
DEFAULT_MAX_BLOCKING_THREADS<u32> = 512

// OS thread entry for multi_thread workers (mirrors blocking_worker_run).
fn mt_os_core_start(){
    sched.worker_entry()
}

// Build-time configuration. sched_kind chooses current_thread vs multi_thread;
// build() routes accordingly.
mem Builder {
    i32   sched_kind                    // 0 = current_thread, 1 = multi_thread
    i32   io_enabled                    // set by enable_io(); not named enable_io (method clash)
    i32   time_enabled                  // set by enable_time()
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
    b.sched_kind                  = KIND_CURRENT_THREAD
    b.io_enabled            = 0
    b.time_enabled          = 0
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
    b.sched_kind = KIND_MULTI_THREAD
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
    this.io_enabled = 1
    return this
}
Builder::enable_time() Builder {
    this.time_enabled = 1
    return this
}
Builder::enable_all() Builder {
    this.io_enabled = 1
    this.time_enabled = 1
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
// a DriverPair plus an optional error code (dummy keeps err intact).
fn build_drivers(b<Builder>) i32, DriverPair, i32 {
    io_drv<rtio.IoDriver>    = null
    io_h<rtio.IoHandle>      = null
    time_drv<rttime.TimeDriver> = null
    time_h<rttime.TimeHandle>   = null
    sig_drv<rtsig.SignalDriver> = null
    sig_h<rtsig.SignalDriverHandle> = null

    if b.io_enabled == 1 {
        ierr<i32> = rtio.IoDriver::new()
        if ierr != 0 return ierr, null, 0
        io_drv = rtio.iodriver_last()
        io_h   = rtio.iohandle_last()
        if io_drv == null || io_h == null return 1, null, 0

        // Signal driver lives on top of the IO driver.
        // Use last() getters — SignalDriver::new triple-ret drops the handle.
        serr<i32> = rtsig.SignalDriver::new(io_drv, io_h)
        if serr == 0 {
            sig_drv = rtsig.signaldriver_last()
            sig_h   = rtsig.signalhandle_last()
        }
    } else {
    }

    if b.time_enabled == 1 {
        // Package bridge + last() getters — dual-ret drops TimeDriver.io_park.
        terr<i32> = rttime.time_driver_new(io_drv)
        if terr == 0 {
            time_drv = rttime.timedriver_last()
            time_h   = rttime.timehandle_last()
        }
    }

    pair<DriverPair> = Driver::compose(io_drv, io_h, time_drv, time_h, sig_drv, sig_h)
    if time_h != null && io_h != null {
        rttime.time_handle_bind_ioh(time_h, io_h)
    }
    return 0, pair, 0
}

// Build a current_thread runtime: shared scheduler + blocking pool +
// optional drivers + a Handle wired to all of the above.
fn build_current_thread(b<Builder>) Runtime {
    err<i32>, pair<DriverPair>, _d<i32> = build_drivers(b)
    if err != 0 || pair == null return null
    drv<Driver> = pair.drv
    drv_h<DriverHandle> = pair.hdl

    pool<rtblk.BlockingPool> = rtblk.BlockingPool::new(b.max_blocking_threads)
    spawner<rtblk.Spawner>   = rtblk.Spawner::new(pool)

    shared<sched.CtShared>   = sched.CtShared::new()
    // Wire both so
    // current_thread block_on can park the reactor (not just osyield).
    if drv != null {
        shared.driver = drv.(u64)
        shared.iod_bits = drv.iod_bits()
    }
    if drv_h != null {
        shared.driver_handle = drv_h.(u64)
        shared.ioh_bits = drv_h.ioh_bits()
    }
    shared.blocking_spawner = spawner.(u64)
    shared.event_interval = b.event_interval
    if shared.event_interval == 0.(u32) {
        shared.event_interval = DEFAULT_EVENT_INTERVAL
    }
    handle<sched.CtHandle>   = sched.CtHandle::new(shared)

    weak<Handle> = Handle::new(handle.(u64), KIND_CURRENT_THREAD, drv_h, spawner.(u64))
    task.poll_ctx_hub_init()
    return Runtime::compose(KIND_CURRENT_THREAD, weak, drv, drv_h, spawner, pool, handle.(u64))
}

// Build a multi_thread runtime: shared MtShared + N workers spawned via
// rtblk.librt_newcore(worker_entry) — library runtime.newcore via blocking bridge.
fn build_multi_thread(b<Builder>) Runtime {
    err<i32>, pair<DriverPair>, _d<i32> = build_drivers(b)
    if err != 0 || pair == null return null
    drv<Driver> = pair.drv
    drv_h<DriverHandle> = pair.hdl

    pool<rtblk.BlockingPool> = rtblk.BlockingPool::new(b.max_blocking_threads)
    spawner<rtblk.Spawner>   = rtblk.Spawner::new(pool)

    shared<sched.MtShared>   = sched.MtShared::new(b.worker_threads)
    handle<sched.MtHandle>   = sched.MtHandle::new(shared)
    handle.driver_handle    = drv_h.(u64)
    handle.blocking_spawner = spawner.(u64)

    weak<Handle> = Handle::new(handle.(u64), KIND_MULTI_THREAD, drv_h, spawner.(u64))
    handle.rt_handle = weak.(u64)

    // Shared driver TryLock for PARKED_DRIVER (mother park Shared).
    if drv != null && drv_h != null {
        time_on<i32> = 0
        if drv_h.time_handle != null {
            time_on = 1
        }
        shared.park_hub = sched.ParkDriverHub::new(
            drv,
            drv_h,
            drv_h.ihandle,
            time_on
        )
    }

    if b.worker_threads > 0 {
        // Init hubs on the builder thread before any clone() worker runs.
        sched.worker_handoff_init()
        sched.mt_ctx_hub_init()
        task.poll_ctx_hub_init()
        for i<u32> = 0 ; i < b.worker_threads ; i += 1 {
            steal_a<sched.Steal>, local_b<sched.Local> = sched.queue_local()
            rng<util.FastRand>     = util.FastRand::new(0xdeadbeef + i.(u64))
            park<sched.Parker>      = sched.Parker::new(shared.park_hub)
            unparker<sched.Unparker> = sched.Unparker::new(park)
            core<sched.WorkerCore>  = sched.WorkerCore::new(local_b, park, rng, b.global_queue_interval)
            worker<sched.MtWorker>  = sched.MtWorker::new(handle, i, core)

            r<sched.Remote> = new sched.Remote
            r.steal_end = steal_a
            r.unparker = unparker
            shared.remotes[i] = r.(u64)

            sched.worker_handoff_publish(worker)
            core_bits<u64> = rtblk.librt_newcore(mt_os_core_start.(u64))
            shared.os_cores[i] = core_bits
            shared.os_cores_len = i + 1
            sched.worker_handoff_wait_claimed()
        }
    }

    return Runtime::compose(KIND_MULTI_THREAD, weak, drv, drv_h, spawner, pool, handle.(u64))
}

// Package-internal build. Runtime stays in-package.
fn builder_build_rt(b<Builder>) Runtime {
    if b.sched_kind == KIND_MULTI_THREAD {
        return build_multi_thread(b)
    }
    return build_current_thread(b)
}

// Build + block_on without shutdown (integration tests that manage teardown).
fn builder_block_on_no_shutdown(b<Builder>, fut_bits<u64>, _unused<i32>) i32, i64 {
    rt<Runtime> = builder_build_rt(b)
    publish_sleep_time_handle(rt)
    err<i32>, val<i64> = rt.block_on_bits(fut_bits)
    return err, val
}

// Build + block_on + shutdown_background in one package call.
// Avoids cross-pkg Runtime returns (codegen drops/corrupts mem with u64 fields).
// fut_bits: raw Future* as u64 — cross-pkg dynamic fut args arrive null.
// Dummy arg keeps multi-return second value (same trap as netio.make_poll).
fn builder_block_on(b<Builder>, fut_bits<u64>, _unused<i32>) i32, i64 {
    rt<Runtime> = builder_build_rt(b)
    // Publish TimeHandle bits for asyncio.runtime.time.Sleep registration
    // (Sleep lives in the time subpackage and cannot import this package).
    publish_sleep_time_handle(rt)
    err<i32>, val<i64> = rt.block_on_bits(fut_bits)
    rt.shutdown_background()
    return err, val
}

// Push the runtime's TimeHandle into the time Sleep registrar.
fn publish_sleep_time_handle(rtv<Runtime>) {
    if rtv == null { return }
    hdl<DriverHandle> = rtv.driver_handle
    if hdl == null { return }
    rttime.sleep_set_handle(hdl.time_handle)
}

// Member sugar matching the design Builder::build — returns Runtime only for
// same-package callers; cross-pkg tests should use builder_block_on.
Builder::build(_unused<i32>) Runtime {
    return builder_build_rt(this)
}
