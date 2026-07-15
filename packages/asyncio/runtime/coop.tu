// Cooperative budget: every leaf future calls poll_proceed before doing
// real work. When the budget hits zero we return PollPending so the
// scheduler gets a chance to run other tasks, preventing one ready
// future from monopolising the worker.
// Mother: tokio::task::coop / budget (rough equivalent).

DEFAULT_BUDGET<i32> = 128

// Returns 0 to proceed (decrement the budget), NoBudget when the task
// must yield. The restore token is non-zero when proceed succeeded; the
// caller hands it back via restore_budget after a long synchronous
// operation if it needs the same slot back.
fn poll_proceed(ctx<u64>) (i32, u64) {
    ctx_slot<RuntimeContext> = current_context()
    if ctx_slot == null {
        return 0, 0
    }
    if ctx_slot.coop_budget <= 0 {
        return RT_NO_BUDGET, 0
    }
    ctx_slot.coop_budget -= 1
    return 0, 1
}

// True while there is at least one budget unit remaining.
fn has_budget_remaining() i32 {
    ctx_slot<RuntimeContext> = current_context()
    if ctx_slot == null {
        return 1
    }
    if ctx_slot.coop_budget > 0 {
        return 1
    }
    return 0
}

// Restore the budget cell taken by poll_proceed. Token is opaque; for
// the first-pass impl we just bump the counter back by one.
fn restore_budget(token<u64>){
    if token == 0 {
        return
    }
    ctx_slot<RuntimeContext> = current_context()
    if ctx_slot == null {
        return
    }
    ctx_slot.coop_budget += 1
}

// Refresh the budget at the top of a poll round.
fn reset_budget(){
    ctx_slot<RuntimeContext> = current_context()
    if ctx_slot == null {
        return
    }
    ctx_slot.coop_budget = DEFAULT_BUDGET
}
