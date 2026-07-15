// Async wrapper over standard input (fd 0). V1 issues read(2) inline on
// poll_read; once the blocking pool is fully wired this should route via
// runtime.blocking.Spawner::spawn_mandatory_blocking so the runtime is
// not stalled by a slow tty.

use std
use runtime
use asyncio.io as aio

mem Stdin {
    i32 fd
}

fn stdin() Stdin {
    s<Stdin> = new Stdin
    s.fd = 0
    return s
}

impl aio.AsyncRead for Stdin {
    fn poll_read(ctx<u64>, buf<aio.ReadBuf>) i32 {
        cap<u64> = buf.remaining()
        if cap == 0 return runtime.PollReady
        ptr<u8*> = buf.unfilled_ptr()
        n<i64> = std.read(this.fd.(i64), ptr, cap)
        if n < 0 return runtime.PollError
        if n > 0 {
            buf.advance(n.(u64))
        }
        return runtime.PollReady
    }
}
