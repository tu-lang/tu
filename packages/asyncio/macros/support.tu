// Combinator support: a helper to poll a child future with the current task
// ctx, plus the Map / Then / Maybe adapter leaves used to shape futures before
// they are fed into select / join / try_join.
//
// poll_child mirrors task.harness_poll's dispatch: it casts the future's
// VObjFunc.entry back to the compiled async entry and calls it with the same
// packed ctx, so a child future's leaves register the enclosing task's waker.

use runtime
use asyncio.runtime as rt

// Compiled async entry signature: (future, packed_ctx) -> (ready, value).
fn future_poll(fut, ctx<u64>) (i64, i64)

// Poll `f` one round, forwarding `ctx`. Returns (ready, value) with ready in
// runtime.PollReady / PollPending / PollError.
fn poll_child(f<runtime.Future>, ctx<u64>) (i64, i64) {
    virf<runtime.VObjFunc> = f.virf
    fc<future_poll> = virf.entry.(u64)
    return fc(f, ctx)
}

// Pick a fair start branch in [0, n) from the runtime's per-worker FastRand.
// Falls back to 0 when there is no active runtime context / rng.
fn select_start(n<u32>) u32 {
    rc<rt.RuntimeContext> = rt.current_context()
    if rc == null return 0
    if rc.rng == null return 0
    return rc.rng.fastrand_n(n)
}

// Map: run `inner`, then transform its resolved value with `transform`.
mem Map: async {
    runtime.Future* inner
    closure         transform    // fn(i64) i64
    i32             done
}

Map::poll(ctx){
    r<i64>, v<i64> = poll_child(this.inner, ctx.(u64))
    if r == runtime.PollPending return runtime.PollPending
    if r == runtime.PollError return runtime.PollError, 0
    this.done = 1
    t<closure> = this.transform
    return runtime.PollReady, t(v)
}

// Then: run `inner`; once it resolves, build the follow-up future via
// `make_next` and drive that to completion (monadic chain).
mem Then: async {
    runtime.Future* inner
    closure         make_next    // fn(i64) runtime.Future
    runtime.Future* next
    i32             stage        // 0 = polling inner, 1 = polling next
}

Then::poll(ctx){
    c<u64> = ctx.(u64)
    if this.stage == 0 {
        r<i64>, v<i64> = poll_child(this.inner, c)
        if r == runtime.PollPending return runtime.PollPending
        if r == runtime.PollError return runtime.PollError, 0
        mk<closure> = this.make_next
        this.next  = mk(v)
        this.stage = 1
    }
    r2<i64>, v2<i64> = poll_child(this.next, c)
    if r2 == runtime.PollReady return runtime.PollReady, v2
    if r2 == runtime.PollError return runtime.PollError, 0
    return runtime.PollPending
}

// Maybe: optionally wrap a future. A null inner resolves immediately to
// `default_val`; otherwise it behaves like `inner`.
mem Maybe: async {
    runtime.Future* inner        // nullable
    i64             default_val
    i32             done
}

Maybe::poll(ctx){
    if this.inner == null {
        this.done = 1
        return runtime.PollReady, this.default_val
    }
    r<i64>, v<i64> = poll_child(this.inner, ctx.(u64))
    if r == runtime.PollPending return runtime.PollPending
    if r == runtime.PollError return runtime.PollError, 0
    this.done = 1
    return runtime.PollReady, v
}
