// Library-function form of join!: drive N futures concurrently and return all
// results once every one has resolved. FastRand picks the polling start each
// round for fairness. Completed branches are never re-polled.

use runtime
use io
use std

// ---- Join2 ---------------------------------------------------------------

mem Join2: async {
    runtime.Future* a
    runtime.Future* b
    i64 ra
    i64 rb
    i32 a_done
    i32 b_done
}

// Poll `a` unless already done; latch its result.
Join2::step_a(c<u64>){
    if this.a_done == 1 return
    r<i64>, v<i64> = poll_child(this.a, c)
    if r == runtime.PollReady { this.a_done = 1; this.ra = v }
}
Join2::step_b(c<u64>){
    if this.b_done == 1 return
    r<i64>, v<i64> = poll_child(this.b, c)
    if r == runtime.PollReady { this.b_done = 1; this.rb = v }
}

Join2::poll(ctx){
    c<u64> = ctx.(u64)
    start<u32> = select_start(2)
    if start == 0 {
        this.step_a(c)
        this.step_b(c)
    } else {
        this.step_b(c)
        this.step_a(c)
    }
    if this.a_done == 1 && this.b_done == 1 return runtime.PollReady, 0
    return runtime.PollPending
}

// Await both futures. Returns (io.Ok, ra, rb) once both resolve.
async join2(a<runtime.Future>, b<runtime.Future>) i32, i64, i64 {
    j<Join2> = new Join2 { a: a, b: b, ra: 0, rb: 0, a_done: 0, b_done: 0 }
    j.await
    return io.Ok, j.ra, j.rb
}

// ---- Join3 ---------------------------------------------------------------

mem Join3: async {
    runtime.Future* a
    runtime.Future* b
    runtime.Future* c
    i64 ra
    i64 rb
    i64 rc
    i32 a_done
    i32 b_done
    i32 c_done
}

Join3::step(idx<u32>, cc<u64>){
    if idx == 0 {
        if this.a_done == 1 return
        r<i64>, v<i64> = poll_child(this.a, cc)
        if r == runtime.PollReady { this.a_done = 1; this.ra = v }
        return
    }
    if idx == 1 {
        if this.b_done == 1 return
        r<i64>, v<i64> = poll_child(this.b, cc)
        if r == runtime.PollReady { this.b_done = 1; this.rb = v }
        return
    }
    if this.c_done == 1 return
    r<i64>, v<i64> = poll_child(this.c, cc)
    if r == runtime.PollReady { this.c_done = 1; this.rc = v }
}

Join3::poll(ctx){
    cc<u64> = ctx.(u64)
    start<u32> = select_start(3)
    for k<u32> = 0 ; k < 3 ; k += 1 {
        this.step((start + k) % 3, cc)
    }
    if this.a_done == 1 && this.b_done == 1 && this.c_done == 1 return runtime.PollReady, 0
    return runtime.PollPending
}

// Await three futures. Returns (io.Ok, ra, rb, rc) once all resolve.
async join3(a<runtime.Future>, b<runtime.Future>, c<runtime.Future>) i32, i64, i64, i64 {
    j<Join3> = new Join3 { a: a, b: b, c: c, ra: 0, rb: 0, rc: 0, a_done: 0, b_done: 0, c_done: 0 }
    j.await
    return io.Ok, j.ra, j.rb, j.rc
}

// ---- Join4 ---------------------------------------------------------------

mem Join4: async {
    runtime.Future* a
    runtime.Future* b
    runtime.Future* c
    runtime.Future* d
    i64 ra
    i64 rb
    i64 rc
    i64 rd
    i32 a_done
    i32 b_done
    i32 c_done
    i32 d_done
}

Join4::step(idx<u32>, cc<u64>){
    if idx == 0 {
        if this.a_done == 1 return
        r<i64>, v<i64> = poll_child(this.a, cc)
        if r == runtime.PollReady { this.a_done = 1; this.ra = v }
        return
    }
    if idx == 1 {
        if this.b_done == 1 return
        r<i64>, v<i64> = poll_child(this.b, cc)
        if r == runtime.PollReady { this.b_done = 1; this.rb = v }
        return
    }
    if idx == 2 {
        if this.c_done == 1 return
        r<i64>, v<i64> = poll_child(this.c, cc)
        if r == runtime.PollReady { this.c_done = 1; this.rc = v }
        return
    }
    if this.d_done == 1 return
    r<i64>, v<i64> = poll_child(this.d, cc)
    if r == runtime.PollReady { this.d_done = 1; this.rd = v }
}

Join4::poll(ctx){
    cc<u64> = ctx.(u64)
    start<u32> = select_start(4)
    for k<u32> = 0 ; k < 4 ; k += 1 {
        this.step((start + k) % 4, cc)
    }
    if this.a_done == 1 && this.b_done == 1 && this.c_done == 1 && this.d_done == 1 return runtime.PollReady, 0
    return runtime.PollPending
}

// Await four futures. Returns (io.Ok, ra, rb, rc, rd) once all resolve.
async join4(a<runtime.Future>, b<runtime.Future>, c<runtime.Future>, d<runtime.Future>) i32, i64, i64, i64, i64 {
    j<Join4> = new Join4 { a: a, b: b, c: c, d: d, ra: 0, rb: 0, rc: 0, rd: 0, a_done: 0, b_done: 0, c_done: 0, d_done: 0 }
    j.await
    return io.Ok, j.ra, j.rb, j.rc, j.rd
}

// ---- general N -----------------------------------------------------------

// Drive N futures to completion, collecting results in input order.
// `dones`/`results` are heap arrays sized n; remaining counts pending futures.
mem JoinAll: async {
    u64* futs
    i32  n
    u64* dones
    i64* results
    i32  remaining
}

JoinAll::poll(ctx){
    cc<u64> = ctx.(u64)
    for i<i32> = 0 ; i < this.n ; i += 1 {
        if this.dones[i] == 0 {
            f<runtime.Future> = this.futs[i].(runtime.Future)
            r<i64>, v<i64> = poll_child(f, cc)
            if r == runtime.PollReady {
                this.dones[i]   = 1
                this.results[i] = v
                this.remaining -= 1
            }
        }
    }
    if this.remaining <= 0 return runtime.PollReady, 0
    return runtime.PollPending
}

// Await N futures. `futs` points at N runtime.Future pointer bits. Returns
// (io.Ok, results) where results[i] is the i-th future's value (input order).
async join_all(futs<u64*>, n<i32>) i32, i64* {
    dones<u64*>     = std.malloc(sizeof(u64) * n.(u64))
    results<i64*>   = std.malloc(sizeof(i64) * n.(u64))
    for i<i32> = 0 ; i < n ; i += 1 {
        dones[i]   = 0
        results[i] = 0
    }
    j<JoinAll> = new JoinAll { futs: futs, n: n, dones: dones, results: results, remaining: n }
    j.await
    return io.Ok, results
}
