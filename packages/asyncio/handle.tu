// Root-package Handle: a thin wrapper over asyncio.runtime.Handle so user
// code spawns / blocks through `use asyncio` without touching the runtime
// subpackage. Every method forwards to the wrapped weak handle.

use asyncio.runtime as rt
use asyncio.runtime.blocking as rtblk
use asyncio.task

// Wraps the runtime's weak Handle.
mem Handle {
    rt.Handle* inner
}

// RAII-style entered-context token returned by Handle::enter. Callers pair it
// with exit() to restore the previous context (no auto-drop in V1).
mem EnterGuard {
    rt.RtSavedSlot* saved
}

// Restore the context that was active before the matching enter().
EnterGuard::exit(){
    rt.rt_exit(this.saved)
}

// The active runtime's Handle, or (err, null) outside any runtime.
const Handle::current() (i32, Handle) {
    err<i32>, h<rt.Handle> = rt.Handle::current()
    if err != 0 return err, null
    return 0, new Handle { inner: h }
}

// Spawn a future on the active scheduler.
Handle::spawn(fut) {
    return this.inner.spawn(fut)
}

// Spawn a synchronous closure on the blocking pool.
Handle::spawn_blocking(op<u64>) {
    return this.inner.spawn_blocking(op)
}

// Run a future to completion on the active runtime.
Handle::block_on(fut) (i32, i64) {
    return this.inner.block_on(fut)
}

// Set this runtime as the active context for the current thread and return a
// guard whose exit() restores the previous context. The context carries a
// null rng (coop / select fairness fall back to their fixed path while
// entered), which is sufficient for the manual enter/exit use.
Handle::enter() EnterGuard {
    bits<u64> = 0
    if this.inner.drv_h != null {
        bits = this.inner.drv_h
    }
    inner_bits<u64> = this.inner.(u64)
    ctx<rt.RuntimeContext> = rt.RuntimeContext::new(
        this.inner.sched_handle,
        inner_bits,
        bits,
        null,
        rt.ENTER_RUNTIME
    )
    saved<rt.RtSavedSlot> = rt.rt_enter(ctx)
    return new EnterGuard { saved: saved }
}
