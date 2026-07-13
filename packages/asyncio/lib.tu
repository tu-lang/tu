// Root-package entry points: after `use asyncio`, callers get spawn /
// spawn_blocking / block_on and a default runtime, all routed through the
// active runtime Handle (asyncio.runtime).

use asyncio.runtime as rt
use asyncio.runtime.blocking as rtblk
use asyncio.task
use asyncio.error as aerr

// Empty JoinHandle used when there is no active runtime to spawn onto.
fn empty_join() task.JoinHandle {
    jh<task.JoinHandle> = new task.JoinHandle
    jh.init(null)
    return jh
}

// Spawn `fut` on the active runtime. Outside a runtime this returns an empty
// JoinHandle rather than aborting.
fn spawn(fut) task.JoinHandle {
    err<i32>, h<rt.Handle> = rt.Handle::current()
    if err != 0 return empty_join()
    return h.spawn(fut)
}

// Spawn a synchronous closure on the active runtime's blocking pool.
fn spawn_blocking(op<u64>) task.JoinHandle {
    err<i32>, h<rt.Handle> = rt.Handle::current()
    if err != 0 return empty_join()
    return h.spawn_blocking(op)
}

// Run `fut` to completion on the active runtime. Returns (RuntimeShutdown, 0)
// when called outside a runtime.
fn block_on(fut) (i32, i64) {
    err<i32>, h<rt.Handle> = rt.Handle::current()
    if err != 0 return aerr.RuntimeShutdown, 0
    return h.block_on(fut)
}

// Build a default multi_thread runtime with all drivers enabled. Returns
// (io.Ok, Runtime) or the builder error. (Deviation: returns the error code
// alongside Runtime, matching Builder::build.)
fn runtime_default() (i32, rt.Runtime) {
    b<rt.Builder> = rt.Builder::new_multi_thread()
    b = b.enable_all()
    return b.build()
}
