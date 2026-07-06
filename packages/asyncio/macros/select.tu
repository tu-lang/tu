// Library-function form of select!: race N futures and return (which, value)
// for the first that resolves. Specialised Select2/3/4 leaves cover the common
// arities; select_all handles the general N. FastRand chooses the polling
// start each round so no branch is structurally favoured (select_biased opts
// out and always starts at index 0).

use runtime
use io
use asyncio.error as aerr

// 1-based branch index of the winning future.
SELECT_FIRST_READY<i32>  = 1
SELECT_SECOND_READY<i32> = 2
SELECT_THIRD_READY<i32>  = 3
SELECT_FOURTH_READY<i32> = 4

// ---- Select2 -------------------------------------------------------------

// Two-way race. which holds the winning branch on completion.
mem Select2: async {
    runtime.Future* a
    runtime.Future* b
    i32 a_done
    i32 b_done
    i32 which
}

// Poll both branches (fair start). Return PollReady with the winner's value
// the first time either resolves; which records the branch.
Select2::poll(ctx){
    c<u64> = ctx.(u64)
    start<u32> = select_start(2)
    if start == 0 {
        ra<i64>, va<i64> = poll_child(this.a, c)
        if ra == runtime.PollReady { this.a_done = 1; this.which = SELECT_FIRST_READY; return runtime.PollReady, va }
        if ra == runtime.PollError { this.which = SELECT_FIRST_READY; return runtime.PollError, 0 }
        rb<i64>, vb<i64> = poll_child(this.b, c)
        if rb == runtime.PollReady { this.b_done = 1; this.which = SELECT_SECOND_READY; return runtime.PollReady, vb }
        if rb == runtime.PollError { this.which = SELECT_SECOND_READY; return runtime.PollError, 0 }
    } else {
        rb<i64>, vb<i64> = poll_child(this.b, c)
        if rb == runtime.PollReady { this.b_done = 1; this.which = SELECT_SECOND_READY; return runtime.PollReady, vb }
        if rb == runtime.PollError { this.which = SELECT_SECOND_READY; return runtime.PollError, 0 }
        ra<i64>, va<i64> = poll_child(this.a, c)
        if ra == runtime.PollReady { this.a_done = 1; this.which = SELECT_FIRST_READY; return runtime.PollReady, va }
        if ra == runtime.PollError { this.which = SELECT_FIRST_READY; return runtime.PollError, 0 }
    }
    return runtime.PollPending
}

// Race `a` and `b`. Returns (which, value): which is SELECT_FIRST_READY or
// SELECT_SECOND_READY, value is the winning future's resolved value.
async select2(a<runtime.Future>, b<runtime.Future>) i32, i64 {
    s<Select2> = new Select2 { a: a, b: b, a_done: 0, b_done: 0, which: 0 }
    v<i64> = s.await
    return s.which, v
}

// ---- Select3 -------------------------------------------------------------

mem Select3: async {
    runtime.Future* a
    runtime.Future* b
    runtime.Future* c
    i32 which
}

// The idx-th branch (0..2).
Select3::nth(i<u32>) runtime.Future {
    if i == 0 return this.a
    if i == 1 return this.b
    return this.c
}

Select3::poll(ctx){
    cc<u64> = ctx.(u64)
    start<u32> = select_start(3)
    for k<u32> = 0 ; k < 3 ; k += 1 {
        idx<u32> = (start + k) % 3
        f<runtime.Future> = this.nth(idx)
        r<i64>, v<i64> = poll_child(f, cc)
        if r == runtime.PollReady { this.which = (idx + 1).(i32); return runtime.PollReady, v }
        if r == runtime.PollError { this.which = (idx + 1).(i32); return runtime.PollError, 0 }
    }
    return runtime.PollPending
}

// Race three futures; which is 1..3.
async select3(a<runtime.Future>, b<runtime.Future>, c<runtime.Future>) i32, i64 {
    s<Select3> = new Select3 { a: a, b: b, c: c, which: 0 }
    v<i64> = s.await
    return s.which, v
}

// ---- Select4 -------------------------------------------------------------

mem Select4: async {
    runtime.Future* a
    runtime.Future* b
    runtime.Future* c
    runtime.Future* d
    i32 which
}

// The idx-th branch (0..3).
Select4::nth(i<u32>) runtime.Future {
    if i == 0 return this.a
    if i == 1 return this.b
    if i == 2 return this.c
    return this.d
}

Select4::poll(ctx){
    cc<u64> = ctx.(u64)
    start<u32> = select_start(4)
    for k<u32> = 0 ; k < 4 ; k += 1 {
        idx<u32> = (start + k) % 4
        f<runtime.Future> = this.nth(idx)
        r<i64>, v<i64> = poll_child(f, cc)
        if r == runtime.PollReady { this.which = (idx + 1).(i32); return runtime.PollReady, v }
        if r == runtime.PollError { this.which = (idx + 1).(i32); return runtime.PollError, 0 }
    }
    return runtime.PollPending
}

// Race four futures; which is 1..4.
async select4(a<runtime.Future>, b<runtime.Future>, c<runtime.Future>, d<runtime.Future>) i32, i64 {
    s<Select4> = new Select4 { a: a, b: b, c: c, d: d, which: 0 }
    v<i64> = s.await
    return s.which, v
}

// ---- general N -----------------------------------------------------------

// General N-way race over `futs` (a raw array of N runtime.Future pointer
// bits). biased == 1 always starts at index 0; otherwise FastRand picks.
mem SelectAll: async {
    u64* futs
    i32  n
    i32  biased
    i32  which
}

SelectAll::poll(ctx){
    cc<u64> = ctx.(u64)
    if this.n <= 0 {
        this.which = 0
        return runtime.PollReady, aerr.RecvEmpty.(i64)
    }
    start<i32> = 0
    if this.biased == 0 start = select_start(this.n.(u32)).(i32)
    for k<i32> = 0 ; k < this.n ; k += 1 {
        idx<i32> = (start + k) % this.n
        f<runtime.Future> = this.futs[idx].(runtime.Future)
        r<i64>, v<i64> = poll_child(f, cc)
        if r == runtime.PollReady { this.which = idx + 1; return runtime.PollReady, v }
        if r == runtime.PollError { this.which = idx + 1; return runtime.PollError, 0 }
    }
    return runtime.PollPending
}

// Race N futures. `futs` points at N consecutive runtime.Future pointer bits.
// Returns (which, value); (0, RecvEmpty) when n == 0. Fair start.
async select_all(futs<u64*>, n<i32>) i32, i64 {
    s<SelectAll> = new SelectAll { futs: futs, n: n, biased: 0, which: 0 }
    v<i64> = s.await
    return s.which, v
}

// Like select_all but never randomises the start (index 0 is preferred).
async select_biased(futs<u64*>, n<i32>) i32, i64 {
    s<SelectAll> = new SelectAll { futs: futs, n: n, biased: 1, which: 0 }
    v<i64> = s.await
    return s.which, v
}
