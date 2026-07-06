// Library-function form of try_join!: drive futures concurrently but
// short-circuit the moment any branch resolves to an error.
//
// Contract (V1): each child future is expected to resolve to an i32 io error
// code carried in its i64 value; a value other than io.Ok is treated as an
// error and stops the join immediately. A PollError from a branch maps to
// aerr.RuntimePollError.

use runtime
use io
use asyncio.error as aerr

// ---- TryJoin2 ------------------------------------------------------------

mem TryJoin2: async {
    runtime.Future* a
    runtime.Future* b
    i64 ra
    i64 rb
    i32 a_done
    i32 b_done
    i32 err        // first non-Ok code seen, 0 while clean
}

// Poll `a` unless done; latch its value and any error.
TryJoin2::step_a(c<u64>){
    if this.a_done == 1 return
    r<i64>, v<i64> = poll_child(this.a, c)
    if r == runtime.PollReady {
        this.a_done = 1
        this.ra     = v
        if v != io.Ok.(i64) this.err = v.(i32)
    } else if r == runtime.PollError {
        this.err = aerr.RuntimePollError
    }
}
TryJoin2::step_b(c<u64>){
    if this.b_done == 1 return
    r<i64>, v<i64> = poll_child(this.b, c)
    if r == runtime.PollReady {
        this.b_done = 1
        this.rb     = v
        if v != io.Ok.(i64) this.err = v.(i32)
    } else if r == runtime.PollError {
        this.err = aerr.RuntimePollError
    }
}

TryJoin2::poll(ctx){
    c<u64> = ctx.(u64)
    if this.err != 0 return runtime.PollReady, 0
    start<u32> = select_start(2)
    if start == 0 {
        this.step_a(c)
        if this.err != 0 return runtime.PollReady, 0
        this.step_b(c)
    } else {
        this.step_b(c)
        if this.err != 0 return runtime.PollReady, 0
        this.step_a(c)
    }
    if this.err != 0 return runtime.PollReady, 0
    if this.a_done == 1 && this.b_done == 1 return runtime.PollReady, 0
    return runtime.PollPending
}

// Await both futures, short-circuiting on the first error. Returns
// (io.Ok, ra, rb) when both succeed, or (err, ra, rb) on short-circuit
// (the un-polled branch's result stays 0).
async try_join2(a<runtime.Future>, b<runtime.Future>) i32, i64, i64 {
    t<TryJoin2> = new TryJoin2 { a: a, b: b, ra: 0, rb: 0, a_done: 0, b_done: 0, err: 0 }
    t.await
    if t.err != 0 return t.err, t.ra, t.rb
    return io.Ok, t.ra, t.rb
}

// ---- TryJoin3 ------------------------------------------------------------

mem TryJoin3: async {
    runtime.Future* a
    runtime.Future* b
    runtime.Future* c
    i64 ra
    i64 rb
    i64 rc
    i32 a_done
    i32 b_done
    i32 c_done
    i32 err
}

TryJoin3::step(idx<u32>, cc<u64>){
    if idx == 0 {
        if this.a_done == 1 return
        r<i64>, v<i64> = poll_child(this.a, cc)
        if r == runtime.PollReady {
            this.a_done = 1
            this.ra     = v
            if v != io.Ok.(i64) this.err = v.(i32)
        } else if r == runtime.PollError {
            this.err = aerr.RuntimePollError
        }
        return
    }
    if idx == 1 {
        if this.b_done == 1 return
        r<i64>, v<i64> = poll_child(this.b, cc)
        if r == runtime.PollReady {
            this.b_done = 1
            this.rb     = v
            if v != io.Ok.(i64) this.err = v.(i32)
        } else if r == runtime.PollError {
            this.err = aerr.RuntimePollError
        }
        return
    }
    if this.c_done == 1 return
    r<i64>, v<i64> = poll_child(this.c, cc)
    if r == runtime.PollReady {
        this.c_done = 1
        this.rc     = v
        if v != io.Ok.(i64) this.err = v.(i32)
    } else if r == runtime.PollError {
        this.err = aerr.RuntimePollError
    }
}

TryJoin3::poll(ctx){
    cc<u64> = ctx.(u64)
    if this.err != 0 return runtime.PollReady, 0
    start<u32> = select_start(3)
    for k<u32> = 0 ; k < 3 ; k += 1 {
        this.step((start + k) % 3, cc)
        if this.err != 0 return runtime.PollReady, 0
    }
    if this.a_done == 1 && this.b_done == 1 && this.c_done == 1 return runtime.PollReady, 0
    return runtime.PollPending
}

// Await three futures, short-circuiting on the first error. Returns
// (io.Ok, ra, rb, rc) or (err, ...) on short-circuit.
async try_join3(a<runtime.Future>, b<runtime.Future>, c<runtime.Future>) i32, i64, i64, i64 {
    t<TryJoin3> = new TryJoin3 { a: a, b: b, c: c, ra: 0, rb: 0, rc: 0, a_done: 0, b_done: 0, c_done: 0, err: 0 }
    t.await
    if t.err != 0 return t.err, t.ra, t.rb, t.rc
    return io.Ok, t.ra, t.rb, t.rc
}
