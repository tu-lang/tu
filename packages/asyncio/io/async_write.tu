// Async write interface. poll_write returns (state, written_bytes);
// poll_flush / poll_shutdown return only state.
//
// Buffer args are u64 bits of library io.Buf — package asyncio.io cannot
// `use io` (short-name clash with this package). Call sites pass buf.(u64).
// Mother: tokio::io::AsyncWrite (default poll_write_vectored -> poll_write).

use runtime

api AsyncWrite {
    fn poll_write(ctx<u64>, buf_bits<u64>) (i32, u64)
    fn poll_flush(ctx<u64>) (i32)
    fn poll_shutdown(ctx<u64>) (i32)
    fn poll_write_vectored(ctx<u64>, bufs_bits<u64>) i32, u64 {
        err<i32>, n<u64> = this.poll_write(ctx, bufs_bits)
        return err, n
    }
    fn is_write_vectored() i32 {
        return 0
    }
}
