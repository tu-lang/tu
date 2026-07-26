// Library-function form of try_join!: short-circuit on first error branch.
// Mother: tokio::try_join!

use runtime
use io

mem TryJoin2: async {
    runtime.Future* fut_a
    runtime.Future* fut_b
    i64 res0
    i64 res1
    i32 a_done
    i32 b_done
}

TryJoin2::poll(ctx){
    packed<u64> = ctx.(u64)
    if this.a_done == 0 {
        ready_i<i64> = 0
        val_i<i64> = 0
        ready_i, val_i = poll_child(this.fut_a, packed)
        if ready_i == runtime.PollReady {
            this.a_done = 1
            this.res0 = val_i
            st_i32<i32> = 0
            st_i32 = val_i
            if st_i32 != io.Ok {
                return runtime.PollReady, st_i32, val_i, 0.(i64)
            }
        } else if ready_i == runtime.PollError {
            return runtime.PollError, 0.(i64), 0.(i64), 0.(i64)
        }
    }
    if this.b_done == 0 {
        ready_j<i64> = 0
        val_j<i64> = 0
        ready_j, val_j = poll_child(this.fut_b, packed)
        if ready_j == runtime.PollReady {
            this.b_done = 1
            this.res1 = val_j
            st2<i32> = 0
            st2 = val_j
            if st2 != io.Ok {
                return runtime.PollReady, st2, 0.(i64), val_j
            }
        } else if ready_j == runtime.PollError {
            return runtime.PollError, 0.(i64), 0.(i64), 0.(i64)
        }
    }
    if this.a_done == 1 && this.b_done == 1 {
        return runtime.PollReady, io.Ok, this.res0, this.res1
    }
    return runtime.PollPending
}

// Early error code when only one branch completed with st != io.Ok.
TryJoin2::early_error_code() i32 {
    if this.a_done == 1 && this.b_done == 0 {
        bits0<i64> = this.res0
        code_a<i32> = bits0.(i32)
        if code_a != io.Ok return code_a
    }
    if this.b_done == 1 && this.a_done == 0 {
        bits1<i64> = this.res1
        code_b<i32> = bits1.(i32)
        if code_b != io.Ok return code_b
    }
    return io.Ok
}

fn try_join2(a<runtime.Future>, b<runtime.Future>) TryJoin2 {
    tj<TryJoin2> = new TryJoin2{}
    tj.fut_a = a
    tj.fut_b = b
    tj.res0 = 0
    tj.res1 = 0
    tj.a_done = 0
    tj.b_done = 0
    return tj
}

fn try_join2_val_b(tj<TryJoin2>) i64 {
    return tj.res1
}

fn try_join2_short_status(tj<TryJoin2>) i32 {
    return tj.early_error_code()
}
