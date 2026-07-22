// Combinator support: poll a child future with the current task ctx, plus
// Map / Then / Maybe adapters used to shape futures before select / join.
//
// poll_child uses Future::poll dynstackcall (same ABI as task.harness_poll).
// Multi-return locals must be predeclared before `a, b = f()` in mem methods
// (typed multi-lhs `a<T>, b<U> = f()` is asmgen-hostile).

use runtime
use asyncio.runtime as rt
use asyncio.util as util

// Poll `f` one round. Must use Future::poll dynstackcall (same as
// task.harness_poll) — calling VObjFunc.entry(f, ctx) directly corrupts
// the multi-return ABI. `ctx` is unused here; the harness publishes the
// task waker via task.ACTIVE_POLL_CTX for leaves that need it.
fn poll_child(f<runtime.Future>, ctx<u64>) (i64, i64) {
    ready_i<i64> = 0
    val_i<i64> = 0
    ready_i, val_i = f.poll()
    return ready_i, val_i
}

// Fair start branch in [0, n) from the runtime's per-worker FastRand.
fn select_start(branch_n<u32>) u32 {
    rc<rt.RuntimeContext> = rt.current_context()
    if rc == null return 0
    if rc.rng == null return 0
    return util.fastrand_n(rc.rng, branch_n)
}

// Map: run inner, then transform (V1: pass-through; transform_bits reserved).
mem Map: async {
    runtime.Future* inner
    u64             transform_bits
    i32             done
}

Map::poll(ctx){
    ready_i<i64> = 0
    val_i<i64> = 0
    ready_i, val_i = poll_child(this.inner, ctx.(u64))
    if ready_i == runtime.PollPending return runtime.PollPending
    if ready_i == runtime.PollError return runtime.PollError, 0.(i64)
    this.done = 1
    return runtime.PollReady, val_i
}

// Then: run inner; V1 resolves with inner value (make_next reserved).
mem Then: async {
    runtime.Future* inner
    u64             make_next_bits
    runtime.Future* next
    i32             stage
}

Then::poll(ctx){
    packed<u64> = ctx.(u64)
    ready_i<i64> = 0
    val_i<i64> = 0
    if this.stage == 0 {
        ready_i, val_i = poll_child(this.inner, packed)
        if ready_i == runtime.PollPending return runtime.PollPending
        if ready_i == runtime.PollError return runtime.PollError, 0.(i64)
        this.stage = 1
        return runtime.PollReady, val_i
    }
    ready_i, val_i = poll_child(this.next, packed)
    if ready_i == runtime.PollReady return runtime.PollReady, val_i
    if ready_i == runtime.PollError return runtime.PollError, 0.(i64)
    return runtime.PollPending
}

// Maybe: null inner resolves to default_val; otherwise polls inner.
mem Maybe: async {
    runtime.Future* inner
    i64             default_val
    i32             done
}

Maybe::poll(ctx){
    if this.inner == null {
        this.done = 1
        return runtime.PollReady, this.default_val
    }
    ready_i<i64> = 0
    val_i<i64> = 0
    ready_i, val_i = poll_child(this.inner, ctx.(u64))
    if ready_i == runtime.PollPending return runtime.PollPending
    if ready_i == runtime.PollError return runtime.PollError, 0.(i64)
    this.done = 1
    return runtime.PollReady, val_i
}
