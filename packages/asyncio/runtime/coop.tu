// Cooperative budget: every leaf future calls poll_proceed before doing
// real work. When the budget hits zero we return PollPending so the
// scheduler gets a chance to run other tasks, preventing one ready
// future from monopolising the worker.

use asyncio.error as aerr

DEFAULT_BUDGET<i32> = 128

// Returns 0 to proceed (decrement the budget), NoBudget when the task
// must yield. The restore token is non-zero when proceed succeeded; the
// caller hands it back via restore_budget after a long synchronous
// operation if it needs the same slot back.
fn poll_proceed(ctx<u64>) (i32, u64) {
    rc<RuntimeContext> = current_context()
    if rc == null return 0, 0
    if rc.coop_budget <= 0 {
        return aerr.NoBudget, 0
    }
    rc.coop_budget -= 1
    return 0, 1
}

// True while there is at least one budget unit remaining.
fn has_budget_remaining() bool {
    rc<RuntimeContext> = current_context()
    if rc == null return true
    if rc.coop_budget > 0 return true
    return false
}

// Restore the budget cell taken by poll_proceed. Token is opaque; for
// the first-pass impl we just bump the counter back by one.
fn restore_budget(token<u64>){
    if token == 0 return
    rc<RuntimeContext> = current_context()
    if rc == null return
    rc.coop_budget += 1
}

// Refresh the budget at the top of a poll round.
fn reset_budget(){
    rc<RuntimeContext> = current_context()
    if rc == null return
    rc.coop_budget = DEFAULT_BUDGET
}

