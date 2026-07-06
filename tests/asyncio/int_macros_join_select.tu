// Integration test for asyncio.macros (task 19.13): join / select / timeout
// over real timer futures on a multi_thread runtime.
//   - join2(sleep 10ms, sleep 20ms) -> both complete
//   - select2(sleep 5ms, sleep 50ms) -> the 5ms branch wins
//   - timeout(20ms, sleep 100ms) -> Elapsed (the timer fires first)
//
// Requires the time driver running on the runtime root. Linux CI validated.

use fmt
use os
use io
use asyncio.runtime as rt
use asyncio.macros as m
use asyncio.time as atime
use asyncio.error as aerr

// join2 of two sleeps resolves once the slower one fires.
async join_sleeps_body() i32 {
    s<i32>, _, _ = m.join2(
        atime.sleep(atime.Duration::from_millis(10)),
        atime.sleep(atime.Duration::from_millis(20))
    ).await
    return s
}

// select2 races two sleeps; the shorter (5ms) branch should win.
async select_sleeps_body() i32 {
    w<i32>, _ = m.select2(
        atime.sleep(atime.Duration::from_millis(5)),
        atime.sleep(atime.Duration::from_millis(50))
    ).await
    if w != m.SELECT_FIRST_READY return io.OtherParse
    return io.Ok
}

// timeout fires before a long sleep completes -> Elapsed.
async timeout_body() i32 {
    e<i32>, _ = m.timeout(
        atime.Duration::from_millis(20),
        atime.sleep(atime.Duration::from_millis(100))
    ).await
    if e != aerr.Elapsed return io.OtherParse
    return io.Ok
}

// Drive future `body` to completion on `r`, aborting on any failure.
fn run_body(r<rt.Runtime>, name<i8*>, body) {
    rerr<i32>, result<i64> = r.block_on(body)
    if rerr != 0 os.dief("block_on failed: %d", rerr)
    if result.(i32) != io.Ok os.dief("macros body failed: %d", result.(i32))
    fmt.println(name)
}

fn int_macros_join_select(){
    fmt.println("int_macros_join_select test")

    b<rt.Builder> = rt.Builder::new_multi_thread()
    b = b.enable_all()
    berr<i32>, r<rt.Runtime> = b.build()
    if berr != 0 os.dief("runtime build failed: %d", berr)

    run_body(r, "  join_sleeps passed", join_sleeps_body())
    run_body(r, "  select_sleeps passed", select_sleeps_body())
    run_body(r, "  timeout passed", timeout_body())

    r.shutdown_background()
    fmt.println("int_macros_join_select passed")
}

fn main(){
    int_macros_join_select()
}
