// Root-package re-exports of the per-thread runtime context helpers, so user
// code can `use asyncio` without reaching into asyncio.runtime.

use asyncio.runtime as rt

// The active runtime Handle, or (err, null) outside any runtime.
fn current_handle() (i32, rt.Handle) {
    return rt.Handle::current()
}

// The active RuntimeContext, or null outside any runtime.
fn current_context() rt.RuntimeContext {
    return rt.current_context()
}
