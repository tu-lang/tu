// Root-package re-exports of the cooperative-budget helpers, forwarding to
// asyncio.runtime.coop so user code can `use asyncio` directly.

use asyncio.runtime as rt

// True while the current task still has cooperative budget (or no runtime).
// Returns 1/0 — matches asyncio.runtime.coop (bool return type is unsafe here).
fn has_budget_remaining() i32 {
    return rt.has_budget_remaining()
}

// Consume one budget unit. Returns (0, token) to proceed, (NoBudget, 0) when
// the task must yield. The token is handed back via restore_budget.
fn poll_proceed(ctx<u64>) (i32, u64) {
    return rt.poll_proceed(ctx)
}
