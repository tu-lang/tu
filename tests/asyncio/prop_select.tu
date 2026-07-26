// Property tests for asyncio.macros (tasks 19.10 / 19.11 / 19.12).
// Child leaves use `new T{}` so Future erasure keeps virf. Fairness runs
// many select2 rounds inside one block_on so FastRand advances (a fresh
// rng per block_on with a fixed seed always picks the same branch).

use fmt
use os
use io
use runtime
use asyncio.runtime as rt
use asyncio.macros as m

mem ReadyVal: async {
    i64 val
}
ReadyVal::poll(ctx) {
    return runtime.PollReady, this.val
}
fn ready_val(x<i64>) runtime.Future {
    f<ReadyVal> = new ReadyVal{}
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
fn never_fut() runtime.Future {
    f<NeverFut> = new NeverFut{}
    f.dummy = 0
    fut<runtime.Future> = f
    return fut
}

fn run_body(body) i32, i64 {
    b<rt.Builder> = rt.Builder::new_current_thread()
    b = b.enable_all()
    rerr<i32>, result<i64> = rt.builder_block_on(b, body, 0)
    return rerr, result
}

// Drive one select2 to completion via member poll (same context / rng).
fn select_once_drive() i32 {
    sf<runtime.Future> = m.select2(ready_val(1), ready_val(2))
    loop {
        st<i64>, w<i64> = sf.poll()
        if st == runtime.PollReady {
            wi<i32> = 0
            wi = w
            return wi
        }
        if st == runtime.PollError return -1
    }
    return -1
}

async fairness_body() {
    first<i32>  = 0
    second<i32> = 0
    for i<i32> = 0 ; i < 400 ; i += 1 {
        w<i32> = select_once_drive()
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

fn fairness_check() i32 {
    rerr<i32>, result<i64> = run_body(fairness_body())
    if rerr != 0 return io.OtherParse
    ri<i32> = 0
    ri = result
    return ri
}

mem JoinRound: async {
    m.Join2* inner
}

const JoinRound::new() JoinRound {
    jf<m.Join2> = m.join2_inner(ready_val(11), ready_val(22))
    f<JoinRound> = new JoinRound{}
    f.inner = jf
    return f
}

JoinRound::poll(ctx) {
    pst<i64> = this.inner.poll(ctx)
    if pst == runtime.PollPending return runtime.PollPending
    a<i64> = m.join2_val_a(this.inner)
    b<i64> = m.join2_val_b(this.inner)
    if a != 11 return runtime.PollReady, io.OtherParse
    if b != 22 return runtime.PollReady, io.OtherParse
    return runtime.PollReady, io.Ok
}

async join_once() {
    st<i32> = JoinRound::new().await
    return st
}

fn join_all_check() i32 {
    rerr<i32>, result<i64> = run_body(join_once())
    if rerr != 0 return io.OtherParse
    ri<i32> = 0
    ri = result
    if ri != io.Ok return io.OtherParse
    return io.Ok
}

mem TryShortWrap: async {
    m.TryJoin2* inner
}

const TryShortWrap::new(closed_bits<i64>) TryShortWrap {
    tj<m.TryJoin2> = m.try_join2(ready_val(closed_bits), never_fut())
    f<TryShortWrap> = new TryShortWrap{}
    f.inner = tj
    return f
}

TryShortWrap::poll(ctx) {
    pst<i64> = this.inner.poll(ctx)
    if pst == runtime.PollPending return runtime.PollPending
    if pst == runtime.PollError return runtime.PollError, 0.(i64)
    code<i32> = m.try_join2_short_status(this.inner)
    return runtime.PollReady, code
}

async try_short_once() {
    closed_bits<i64> = 0x03020002.(i64)
    st<i32> = TryShortWrap::new(closed_bits).await
    return st
}

fn try_short_check() i32 {
    rerr<i32>, result<i64> = run_body(try_short_once())
    if rerr != 0 return io.OtherParse
    ri<i32> = 0
    ri = result
    if ri != 0x03020002 return io.OtherParse
    return io.Ok
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
