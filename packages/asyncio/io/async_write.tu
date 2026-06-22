// Async write interface. poll_write returns (state, written_bytes);
// poll_flush / poll_shutdown return only state.

use runtime
use io as iobuf

// IO operations vector for write-side async types. poll_write_vectored
// has a default implementation that falls back to a single poll_write
// over bufs[0]; concrete impls can override.
api AsyncWrite {
    fn poll_write(ctx<u64>, buf<iobuf.Buf>) (i32, u64)
    fn poll_flush(ctx<u64>) i32
    fn poll_shutdown(ctx<u64>) i32
    fn poll_write_vectored(ctx<u64>, bufs<iobuf.Buf>) (i32, u64) {
        // Default: write the first buffer and return whatever poll_write produced.
        return this.poll_write(ctx, bufs)
    }
    fn is_write_vectored() bool {
        return false
    }
}
