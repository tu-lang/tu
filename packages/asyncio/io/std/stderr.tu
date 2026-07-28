// Async wrapper over standard error (fd 2). V1 issues write(2) inline.
// In package asyncio.io.std — can use library io.

use std
use io as iobuf
use runtime
use asyncio.io as aio
use asyncio.io.util as ioutil

mem Stderr {
    i32 fd
}

fn stderr() Stderr {
    s<Stderr> = new Stderr
    s.fd = 2
    return s
}

impl ioutil.AsyncWrite for Stderr {
    fn poll_write(ctx<u64>, buf<iobuf.Buf>) (i32, u64) {
        len<u64> = buf.len()
        ptr<i8*> = buf.ptr()
        if len == 0 return runtime.PollReady, 0
        n<i64> = std.write(this.fd.(i64), ptr, len)
        if n < 0 return runtime.PollError, 0
        return runtime.PollReady, n.(u64)
    }
    fn poll_flush(ctx<u64>) i32 {
        return runtime.PollReady
    }
    fn poll_shutdown(ctx<u64>) i32 {
        return runtime.PollReady
    }
}
