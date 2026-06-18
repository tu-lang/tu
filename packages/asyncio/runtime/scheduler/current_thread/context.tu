// Single-threaded scheduler context. The current_thread scheduler runs on
// exactly one OS thread (the block_on caller), so the context lives in a
// module-level slot that ct_enter / ct_exit save and restore.
// is_current_handle compares pointer identity against the active context.

// Context active on the block_on thread; null outside block_on.
ACTIVE_CT<CtContext*> = null

// Per-thread context combining handle + core + defer.
mem CtContext {
    CtHandle* handle
    Core*     core
    Defer*    defer
}

// Build a context bundling handle / core / defer.
const CtContext::new(handle<CtHandle>, core<Core>, defer<Defer>) CtContext* {
    c<CtContext> = new CtContext
    c.handle = handle
    c.core   = core
    c.defer  = defer
    return &c
}

// Snapshot saved by ct_enter so nested enter/exit pairs unwind correctly.
mem CtSavedSlot {
    CtContext* prev
}

// Push a new context onto the slot; return the saved previous value.
fn ct_enter(ctx<CtContext>) CtSavedSlot {
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
fn current_ct() CtContext* {
    return ACTIVE_CT
}

// True when h is the handle of the active context.
fn is_current_handle(h<CtHandle>) bool {
    cur<CtContext> = ACTIVE_CT
    if cur == null return false
    if cur.handle == h return true
    return false
}

