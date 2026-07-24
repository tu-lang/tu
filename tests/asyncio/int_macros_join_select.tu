// Integration test for asyncio.macros (task 19.13): join / select / timeout
// over real timer futures. Mother: tokio::join! / select! / time::timeout.
// Drive via builder_block_on (same path as int_fs_roundtrip / int_tcp_echo).

use fmt
use os
use io
use string
use runtime
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

// select2 races two sleeps; the shorter (5ms) branch should win.
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
    body_f<runtime.Future> = body
    fut<u64> = 0
    fut = body_f
    rerr<i32>, result<i64> = rt.builder_block_on(b, fut, 0)
    if rerr != 0 os.dief("block_on failed: %d", rerr)
    ri<i32> = 0
    ri = result
    if ri != io.Ok os.dief("macros body failed: %d", ri)
    fmt.println(string.new(name))
}

fn int_macros_join_select(){
    fmt.println("int_macros_join_select test")
    run_body("  join_sleeps passed", join_sleeps_body())
    run_body("  select_sleeps passed", select_sleeps_body())
    fmt.println("int_macros_join_select passed")
}

fn main(){
    int_macros_join_select()
}
