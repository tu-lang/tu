// Integration test for asyncio.macros (task 19.13): join / select / timeout
// over real timer futures.
// Drive via builder_block_on (same path as int_fs_roundtrip / int_tcp_echo).

use fmt
use os
use io
use string
use asyncio.runtime as rt
use asyncio.macros as m
use asyncio.time as atime

// join2 of two sleeps resolves once the slower one fires.
async join_sleeps_body() {
    status<i32> = m.join2(
        atime.sleep(atime.from_millis(10)),
        atime.sleep(atime.from_millis(20))
    ).await
    return status
}

// select2 races two sleeps; only the shorter arm should be Ready when park
// respects next_timer (5ms slice). Fair start still returns FIRST when the
// long arm is still Pending.
async select_sleeps_body() {
    w<i32> = m.select2(
        atime.sleep(atime.from_millis(5)),
        atime.sleep(atime.from_millis(50))
    ).await
    // SELECT_FIRST_READY == 1 (asyncio.macros)
    first<i32> = 1
    if w != first {
        bad<i32> = io.OtherParse
        return bad
    }
    ok<i32> = io.Ok
    return ok
}

// Drive one body on a fresh current_thread runtime with time enabled.
fn run_body(name<i8*>, body) {
    b<rt.Builder> = rt.Builder::new_current_thread()
    b = b.enable_all()
    rerr<i32>, result<i64> = rt.builder_block_on(b, body, 0)
    if rerr != 0 os.dief("block_on failed: %d", rerr)
    ri<i32> = 0
    ri = result
    if ri != io.Ok os.dief("macros body failed: %d", ri)
    fmt.println(string.new(name))
}

fn run_body_mt(name<i8*>, body) {
    b<rt.Builder> = rt.Builder::new_multi_thread()
    b = b.worker_threads(4)
    b = b.enable_all()
    rerr<i32>, result<i64> = rt.builder_block_on(b, body, 0)
    if rerr != 0 os.dief("mt block_on failed: %d", rerr)
    ri<i32> = 0
    ri = result
    if ri != io.Ok os.dief("mt macros body failed: %d", ri)
    fmt.println(string.new(name))
}

// timeout(20ms, sleep 100ms) must surface Elapsed before the sleep completes.
TIMEOUT_ELAPSED<i32> = 0x03020004

async timeout_elapsed_body() {
    code<i32> = m.timeout(
        atime.from_millis(20),
        atime.sleep(atime.from_millis(100))
    ).await
    if code != TIMEOUT_ELAPSED {
        bad<i32> = io.OtherParse
        return bad
    }
    ok<i32> = io.Ok
    return ok
}

fn int_macros_join_select(){
    fmt.println("int_macros_join_select test")
    run_body("  join_sleeps passed", join_sleeps_body())
    run_body("  select_sleeps passed", select_sleeps_body())
    run_body("  timeout_elapsed passed", timeout_elapsed_body())
    fmt.println("int_macros_join_select passed")
}

fn int_macros_join_select_mt(){
    fmt.println("int_macros_join_select_mt test")
    run_body_mt("  mt join_sleeps passed", join_sleeps_body())
    run_body_mt("  mt select_sleeps passed", select_sleeps_body())
    run_body_mt("  mt timeout_elapsed passed", timeout_elapsed_body())
    // Second MT runtime after join/select/timeout must stay clean.
    run_body_mt("  mt join_sleeps again passed", join_sleeps_body())
    fmt.println("int_macros_join_select_mt passed")
}

fn main(){
    int_macros_join_select()
    int_macros_join_select_mt()
}
