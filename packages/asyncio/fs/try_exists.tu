// fs_try_exists: test whether a path exists.

use std
use io
use string
use sys
use runtime

// Leaf: stat(2); returns (err, exists_flag) with exists_flag i32 0/1.
mem TryExistsFut: async {
    string.String path
    u64 pad
}

TryExistsFut::poll(ctx) {
    s<std.Stat> = new std.Stat
    pc<i8*> = string.cstr(this.path)
    err<i32>, junk<u64> = sys.cvt(sys.stat(pc, s.(u64)))
    ok_code<i32> = io.Ok
    zero<i32> = 0
    one<i32> = 1
    not_found<i32> = io.NotFound
    ready<i32> = runtime.PollReady
    if err == ok_code return ready, ok_code, one
    if err == not_found return ready, ok_code, zero
    return ready, err, zero
}

// Concrete leaf (same pattern as ctrl_c / UdpRecvFut); callers `.await` it.
fn fs_try_exists(path<string.String>) TryExistsFut {
    return new TryExistsFut { path: path, pad: 0 }
}
