// Bridge test: asyncio.wrapper tcp_echo job.

use fmt
use os
use io
use runtime
use asyncio.wrapper as wrap

fn int_wrapper_tcp() {
    body_f<runtime.Future> = wrap.tcp_echo(*"127.0.0.1:18181")
    err<i32>, val<i64> = wrap.block_on_ct(body_f.(u64))
    if err != 0 {
        os.dief("wrap.block_on_ct failed: %d", err)
    }
    ri<i32> = val
    if ri != io.Ok {
        os.dief("wrapper tcp echo failed: %d", ri)
    }
    fmt.println("int_wrapper_tcp passed")
}

fn main() {
    int_wrapper_tcp()
}
