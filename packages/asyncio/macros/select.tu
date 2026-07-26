// Library-function form of select!: race futures and return (which, value)
// for the first that resolves. Mother: tokio::select!.

use runtime
use io

SELECT_FIRST_READY<i32>  = 1
SELECT_SECOND_READY<i32> = 2

mem Select2: async {
    runtime.Future* fut_a
    runtime.Future* fut_b
    i32 a_done
    i32 b_done
    i32 which
}

Select2::poll(ctx){
    packed<u64> = ctx.(u64)
    start<u32> = select_start(2)
    ready_a<i64> = 0
    val_a<i64> = 0
    ready_b<i64> = 0
    val_b<i64> = 0
    if start == 0 {
        ready_a, val_a = poll_child(this.fut_a, packed)
        if ready_a == runtime.PollReady {
            this.a_done = 1
            this.which = SELECT_FIRST_READY
            return runtime.PollReady, SELECT_FIRST_READY, val_a
        }
        if ready_a == runtime.PollError {
            this.which = SELECT_FIRST_READY
            return runtime.PollError, SELECT_FIRST_READY, 0.(i64)
        }
        ready_b, val_b = poll_child(this.fut_b, packed)
        if ready_b == runtime.PollReady {
            this.b_done = 1
            this.which = SELECT_SECOND_READY
            return runtime.PollReady, SELECT_SECOND_READY, val_b
        }
        if ready_b == runtime.PollError {
            this.which = SELECT_SECOND_READY
            return runtime.PollError, SELECT_SECOND_READY, 0.(i64)
        }
    } else {
        ready_b, val_b = poll_child(this.fut_b, packed)
        if ready_b == runtime.PollReady {
            this.b_done = 1
            this.which = SELECT_SECOND_READY
            return runtime.PollReady, SELECT_SECOND_READY, val_b
        }
        if ready_b == runtime.PollError {
            this.which = SELECT_SECOND_READY
            return runtime.PollError, SELECT_SECOND_READY, 0.(i64)
        }
        ready_a, val_a = poll_child(this.fut_a, packed)
        if ready_a == runtime.PollReady {
            this.a_done = 1
            this.which = SELECT_FIRST_READY
            return runtime.PollReady, SELECT_FIRST_READY, val_a
        }
        if ready_a == runtime.PollError {
            this.which = SELECT_FIRST_READY
            return runtime.PollError, SELECT_FIRST_READY, 0.(i64)
        }
    }
    return runtime.PollPending
}

fn select2(a<runtime.Future>, b<runtime.Future>) runtime.Future {
    // Plain new T{} — struct literals can leave async virf null.
    s<Select2> = new Select2{}
    s.fut_a = a
    s.fut_b = b
    s.a_done = 0
    s.b_done = 0
    s.which = 0
    fut<runtime.Future> = s
    return fut
}
