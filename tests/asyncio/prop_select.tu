// Property tests for asyncio.macros (tasks 19.10 / 19.11 / 19.12):
//   - prop_select_fairness: select2 over two ready futures picks each branch
//     first with near-equal frequency (FastRand start).
//   - prop_join_all_complete: join2 resolves once both futures complete and
//     returns both results in order.
//   - prop_try_join_short_circuit: try_join2 short-circuits on an error branch
//     without needing the other (pending) branch to complete.
//
// Uses immediate / never-ready futures so no timer driver is required; the
// fairness property additionally relies on the runtime rng being wired. Linux
// CI validated.

use fmt
use os
use io
use runtime
use asyncio.runtime as rt
use asyncio.macros as m
use asyncio.error as aerr

// Resolve immediately to `x`.
async ready_val(x<i64>) i64 {
    return x
}

// A future that never resolves; used to prove try_join short-circuits.
mem NeverFut: async {
    i32 dummy
}
NeverFut::poll(ctx){
    return runtime.PollPending
}
async never_fut() i64 {
    n<NeverFut> = new NeverFut { dummy: 0 }
    return n.await
}

// task 19.10: over many rounds, neither select2 branch wins far more often.
async fairness_body() i32 {
    first<i32>  = 0
    second<i32> = 0
    for i<i32> = 0 ; i < 400 ; i += 1 {
        w<i32>, _ = m.select2(ready_val(1), ready_val(2)).await
        if w == m.SELECT_FIRST_READY {
            first += 1
        } else {
            second += 1
        }
    }
    // Both branches ready => winner is the rng-chosen start branch; expect a
    // near 50/50 split. 5% target; allow 15% (60/400) slack for sample noise.
    diff<i32> = first - second
    if diff < 0 diff = -diff
    if diff > 60 return io.OtherParse
    return io.Ok
}

// task 19.11: join2 completes with both results once both futures resolve.
async join_all_body() i32 {
    s<i32>, ra<i64>, rb<i64> = m.join2(ready_val(11), ready_val(22)).await
    if s != io.Ok return s
    if ra != 11 return io.OtherParse
    if rb != 22 return io.OtherParse
    return io.Ok
}

// task 19.12: try_join2 short-circuits when a branch resolves to an error,
// even though the other branch never completes.
async try_short_body() i32 {
    st<i32>, _, rb<i64> = m.try_join2(ready_val(aerr.Closed.(i64)), never_fut()).await
    if st != aerr.Closed return io.OtherParse
    if rb != 0 return io.OtherParse
    return io.Ok
}

// Drive future `body` to completion on `r`, aborting on any failure.
fn run_body(r<rt.Runtime>, name<i8*>, body) {
    rerr<i32>, result<i64> = r.block_on(body)
    if rerr != 0 os.dief("block_on failed: %d", rerr)
    if result.(i32) != io.Ok os.dief("prop body failed: %d", result.(i32))
    fmt.println(name)
}

fn prop_select(){
    fmt.println("prop_select test")

    b<rt.Builder> = rt.Builder::new_current_thread()
    b = b.enable_all()
    berr<i32>, r<rt.Runtime> = b.build()
    if berr != 0 os.dief("runtime build failed: %d", berr)

    run_body(r, "  prop_select_fairness passed", fairness_body())
    run_body(r, "  prop_join_all_complete passed", join_all_body())
    run_body(r, "  prop_try_join_short_circuit passed", try_short_body())

    r.shutdown_background()
    fmt.println("prop_select passed")
}

fn main(){
    prop_select()
}
