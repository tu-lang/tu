// Async wrapper over standard output (fd 1). V1 issues write(2) inline.
// In package asyncio.io.std — can use library io.

use std
use io as iobuf
use runtime
use asyncio.io as aio
use asyncio.io.util as ioutil

mem Stdout {
    i32 fd
}

fn stdout() Stdout {
    s<Stdout> = new Stdout
    s.fd = 1
    return s
}

impl ioutil.AsyncWrite for Stdout {
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
