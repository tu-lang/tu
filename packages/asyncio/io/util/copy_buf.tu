// Buffered AsyncBufRead -> AsyncWrite pump. Avoids the temporary
// scratch buffer copy() needs by handing the buffered slice straight
// to write_all and then telling the source to consume it.

use runtime
use io as iobuf
use asyncio.io as aio
use asyncio.io.util as aiou

// Pump bytes from buffered reader `br` to writer `w` until EOF.
// Returns (0, total) on success; (err, total) when fill_buf or
// write_all surfaced an error.
async copy_buf(br<u64>, w<u64>) (i32, u64) {
    total<u64> = 0
    loop {
        rerr<i32>, slice<iobuf.Buf> = aiou.fill_buf(br).await
        if rerr != 0 return rerr, total
        n<u64> = slice.len()
        if n == 0 return 0, total
        werr<i32> = aiou.write_all(w, slice).await
        if werr != 0 return werr, total
        br.(aio.AsyncBufRead).consume(n)
        total = total + n
    }
}
