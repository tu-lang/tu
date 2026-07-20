// Library-function form of try_join!: short-circuit on first error branch.
// Mother: tokio::try_join!

use runtime
use io

mem TryJoin2: async {
    runtime.Future* fut_a
    runtime.Future* fut_b
    i64 ra
    i64 rb
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
            this.ra = val_i
            st_i32<i32> = 0
            st_i32 = val_i
            if st_i32 != io.Ok {
                return runtime.PollReady, st_i32, val_i, 0
            }
        } else if ready_i == runtime.PollError {
            return runtime.PollError, 0, 0, 0
        }
    }
    if this.b_done == 0 {
        ready_j<i64> = 0
        val_j<i64> = 0
        ready_j, val_j = poll_child(this.fut_b, packed)
        if ready_j == runtime.PollReady {
            this.b_done = 1
            this.rb = val_j
            st2<i32> = 0
            st2 = val_j
            if st2 != io.Ok {
                return runtime.PollReady, st2, 0, val_j
            }
        } else if ready_j == runtime.PollError {
            return runtime.PollError, 0, 0, 0
        }
    }
    if this.a_done == 1 && this.b_done == 1 {
        return runtime.PollReady, io.Ok, this.ra, this.rb
    }
    return runtime.PollPending
}

fn try_join2(a<runtime.Future>, b<runtime.Future>) TryJoin2 {
    return new TryJoin2 {
        fut_a: a, fut_b: b,
        ra: 0, rb: 0,
        a_done: 0, b_done: 0
    }
}
