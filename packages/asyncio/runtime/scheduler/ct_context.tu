// Single-threaded scheduler context. Only the block_on OS thread may treat
// the context as "current". ACTIVE_CT is a process slot; owner_tid gates
// foreign threads (blocking pool) so they take inject + driver unpark.

use std

// Context active on the block_on thread; null outside block_on.
// Not true TLS: always pair with owner_tid in is_current_handle.
ACTIVE_CT<CtContext> = null

// Per-thread context combining handle + core + defer.
mem CtContext {
    CtHandle* handle
    Core*     core
    Defer*    defer
    u64       owner_tid    // gettid of block_on thread (TLS surrogate)
}

// Build a context bundling handle / core / defer.
const CtContext::new(handle<CtHandle>, core<Core>, defer<Defer>) CtContext {
    c<CtContext> = new CtContext
    c.handle = handle
    c.core   = core
    c.defer  = defer
    c.owner_tid = 0
    return c
}

// Snapshot saved by ct_enter so nested enter/exit pairs unwind correctly.
mem CtSavedSlot {
    CtContext* prev
}

// Push a new context onto the slot; return the saved previous value.
fn ct_enter(ctx<CtContext>) CtSavedSlot {
    ctx.owner_tid = std.gettid()
    saved<CtSavedSlot> = new CtSavedSlot
    saved.prev = ACTIVE_CT
    ACTIVE_CT  = ctx
    return saved
}

// Restore the previous context; pairs with ct_enter.
fn ct_exit(saved<CtSavedSlot>){
    ACTIVE_CT = saved.prev
}

// Currently active context; null outside block_on.
// Callers on foreign threads must not treat this as current (see is_current_handle).
fn current_ct() CtContext {
    cur<CtContext> = ACTIVE_CT
    if cur == null return null
    if cur.owner_tid != std.gettid() return null
    return cur
}

// True when h is the handle of the active context on *this* OS thread.
fn is_current_handle(h<CtHandle>) i32 {
    cur<CtContext> = ACTIVE_CT
    if cur == null return 0
    if cur.owner_tid != std.gettid() return 0
    if cur.handle == h return 1
    return 0
}
