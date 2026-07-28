// Async write interface. poll_write returns (state, written_bytes);
// poll_flush / poll_shutdown return only state.
//
// Lives in asyncio.io.util (not asyncio.io): the parent package short name
// is `io`, so `use io` / `use io as libio` there poisons type lookup
// (`static class not exist:io.AsyncWrite`). This package short name is
// `util` and may import library io safely.

use runtime
use io as iobuf

api AsyncWrite {
    fn poll_write(ctx<u64>, buf<iobuf.Buf>) i32, u64 {
        return runtime.PollError, 0.(u64)
    }
    fn poll_flush(ctx<u64>) i32 {
        return runtime.PollError
    }
    fn poll_shutdown(ctx<u64>) i32 {
        return runtime.PollError
    }
    fn poll_write_vectored(ctx<u64>, bufs<iobuf.Buf>) i32, u64 {
        err<i32>, n<u64> = this.poll_write(ctx, bufs)
        return err, n
    }
    fn is_write_vectored() i32 {
        return 0
    }
}
