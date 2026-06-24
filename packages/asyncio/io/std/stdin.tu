// Async wrapper over standard input (fd 0). V1 issues read(2) inline on
// poll_read; once the blocking pool is fully wired this should route via
// runtime.blocking.Spawner::spawn_mandatory_blocking so the runtime is
// not stalled by a slow tty.

use std
use io as iobuf
use runtime
use asyncio.io as aio

// Stdin: AsyncRead over file descriptor 0.
mem Stdin {
    i32 fd      // always 0
}

// Build the stdin handle.
const stdin() Stdin {
    s<Stdin> = new Stdin
    s.fd = 0
    return s
}

// Forward poll_read directly to read(2). Returns runtime.PollReady on
// success (including EOF, where buf.filled does not advance) or
// runtime.PollError on syscall failure.
// TEMP: V1 synchronous; replace with blocking-pool dispatch once
// runtime.blocking.Spawner::spawn_mandatory_blocking is fully wired.
impl aio.AsyncRead for Stdin {
    fn poll_read(ctx<u64>, buf<aio.ReadBuf>) i32 {
        inner<iobuf.Buffer> = buf.initialize_unfilled()
        slice<iobuf.Buf>    = inner.buf
        cap<u64>            = buf.remaining()
        if cap == 0 return runtime.PollReady
        ptr<u64*>           = slice.inner.(u64*)
        n<i64>              = std.read(this.fd.(i64), ptr, cap)
        if n < 0 return runtime.PollError
        if n > 0 {
            // Advance the filled cursor so the caller observes new bytes.
            // ReadBuf::advance returns -1 only if n exceeds remaining,
            // which the cap check above prevents.
            buf.advance(n.(u64))
        }
        return runtime.PollReady
    }
}
