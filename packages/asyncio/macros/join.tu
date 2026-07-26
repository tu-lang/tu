// Library-function form of join!: drive futures concurrently until all resolve.
// Mother: tokio::join! — fair poll start via FastRand; completed branches skipped.

use runtime
use io

mem Join2: async {
    runtime.Future* fut_a
    runtime.Future* fut_b
    i64 res0
    i64 res1
    i32 a_done
    i32 b_done
}

Join2::step_a(packed<u64>){
    if this.a_done == 1 { return }
    ready_i<i64> = 0
    val_i<i64> = 0
    ready_i, val_i = poll_child(this.fut_a, packed)
    if ready_i == runtime.PollReady {
        this.a_done = 1
        this.res0 = val_i
    }
}

Join2::step_b(packed<u64>){
    if this.b_done == 1 { return }
    ready_i<i64> = 0
    val_i<i64> = 0
    ready_i, val_i = poll_child(this.fut_b, packed)
    if ready_i == runtime.PollReady {
        this.b_done = 1
        this.res1 = val_i
    }
}

Join2::poll(ctx){
    packed<u64> = ctx.(u64)
    start<u32> = select_start(2)
    if start == 0 {
        this.step_a(packed)
        this.step_b(packed)
    } else {
        this.step_b(packed)
        this.step_a(packed)
    }
    ok_code<i32> = io.Ok
    if this.a_done == 1 && this.b_done == 1 {
        return runtime.PollReady, ok_code, this.res0, this.res1
    }
    return runtime.PollPending
}

fn join2_inner(a<runtime.Future>, b<runtime.Future>) Join2 {
    j<Join2> = new Join2{}
    j.fut_a = a
    j.fut_b = b
    j.res0 = 0
    j.res1 = 0
    j.a_done = 0
    j.b_done = 0
    return j
}

fn join2(a<runtime.Future>, b<runtime.Future>) runtime.Future {
    j<Join2> = join2_inner(a, b)
    fut<runtime.Future> = j
    return fut
}

fn join2_val_a(j<Join2>) i64 {
    return j.res0
}

fn join2_val_b(j<Join2>) i64 {
    return j.res1
}
