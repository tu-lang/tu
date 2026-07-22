// Property tests for asyncio.macros (tasks 19.10 / 19.11 / 19.12).

use fmt
use os
use io
use runtime
use asyncio.runtime as rt
use asyncio.macros as m
use asyncio.error as aerr

mem ReadyVal: async {
    i64 val
}
ReadyVal::poll(ctx) {
    return runtime.PollReady, this.val
}
fn ready_val(x<i64>) runtime.Future {
    f<ReadyVal> = new ReadyVal
    f.val = x
    fut<runtime.Future> = f
    return fut
}

mem NeverFut: async {
    i32 dummy
}
NeverFut::poll(ctx){
    return runtime.PollPending
}
fn never_fut() NeverFut {
    return new NeverFut { dummy: 0 }
}

mem SelectRound: async {
    m.Select2* inner
    i32       which
}

const SelectRound::new() SelectRound {
    fa<runtime.Future> = ready_val(1)
    fb<runtime.Future> = ready_val(2)
    sf<m.Select2> = m.select2(fa, fb)
    return new SelectRound { inner: sf, which: 0 }
}

SelectRound::poll(ctx) {
    pst<i64> = this.inner.poll(ctx)
    if pst == runtime.PollPending return runtime.PollPending
    this.which = this.inner.which
    return runtime.PollReady, this.which
}

fn fairness_check() i32 {
    first<i32>  = 0
    second<i32> = 0
    for i<i32> = 0 ; i < 400 ; i += 1 {
        sr<SelectRound> = SelectRound::new()
        w_val<i64> = runtime.block(sr)
        w<i32> = w_val.(i32)
        if w == 1 {
            first += 1
        } else {
            second += 1
        }
    }
    diff<i32> = first - second
    if diff < 0 {
        diff = second - first
    }
    if diff > 60 return io.OtherParse
    return io.Ok
}

mem JoinRound: async {
    m.Join2* inner
    i64     first_result
    i64     second_result
}

const JoinRound::new() JoinRound {
    ja<runtime.Future> = ready_val(11)
    jb<runtime.Future> = ready_val(22)
    jf<m.Join2> = m.join2(ja, jb)
    return new JoinRound { inner: jf, first_result: 0, second_result: 0 }
}

JoinRound::poll(ctx) {
    pst<i64> = this.inner.poll(ctx)
    if pst == runtime.PollPending return runtime.PollPending
    this.first_result = m.join2_val_a(this.inner)
    this.second_result = m.join2_val_b(this.inner)
    return runtime.PollReady, io.Ok
}

fn join_all_check() i32 {
    jr<JoinRound> = JoinRound::new()
    st_val<i64> = runtime.block(jr)
    st<i32> = st_val.(i32)
    if st != io.Ok return st
    if jr.first_result != 11 return io.OtherParse
    if jr.second_result != 22 return io.OtherParse
    return io.Ok
}

mem TryJoinRound: async {
    m.TryJoin2* inner
    i32         status_code
    i64         second_result
}

const TryJoinRound::new() TryJoinRound {
    closed_bits<i64> = 0x03020002.(i64)
    tj<m.TryJoin2> = m.try_join2(ready_val(closed_bits), never_fut())
    return new TryJoinRound { inner: tj, status_code: 0, second_result: 0 }
}

TryJoinRound::poll(ctx) {
    pst<i64> = this.inner.poll(ctx)
    if pst == runtime.PollPending return runtime.PollPending
    if pst == runtime.PollError return runtime.PollError, 0.(i64)
    this.second_result = m.try_join2_val_b(this.inner)
    this.status_code = m.try_join2_short_status(this.inner)
    return runtime.PollReady, this.status_code
}

fn try_short_check() i32 {
    tjr<TryJoinRound> = TryJoinRound::new()
    st_val<i64> = runtime.block(tjr)
    st<i32> = st_val.(i32)
    if st != 0x03020002 return io.OtherParse
    if tjr.second_result != 0 return io.OtherParse
    return io.Ok
}

fn run_body(r<rt.Runtime>, name<i8*>, body) {
    rerr<i32>, result<i64> = r.block_on(body)
    if rerr != 0 os.dief("block_on failed: %d", rerr)
    if result.(i32) != io.Ok os.dief("prop body failed: %d", result.(i32))
    fmt.println(name)
}

fn prop_select(){
    fmt.println("prop_select test")

    if fairness_check() != io.Ok os.dief("prop_select_fairness failed")
    fmt.println("  prop_select_fairness passed")
    if join_all_check() != io.Ok os.dief("prop_join_all_complete failed")
    fmt.println("  prop_join_all_complete passed")
    if try_short_check() != io.Ok os.dief("prop_try_join_short_circuit failed")
    fmt.println("  prop_try_join_short_circuit passed")

    fmt.println("prop_select passed")
}

fn main(){
    prop_select()
}
