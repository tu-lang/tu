// Generic AsyncRead -> AsyncWrite pump. Internally uses a small heap
// buffer driven via the existing read/write leaf futures so callers do
// not need to bring their own io.buffer.Buffer.

use runtime
use io as iobuf
use asyncio.io as aio
use asyncio.io.util as aiou

// Default scratch buffer size for copy(). Tuned for typical net /
// pipe sizes; callers that want a different size should drive copy_buf
// directly with their own BufReader.
COPY_DEFAULT_CAP<u64> = 8192

// Pump bytes from `r` to `w` until EOF. Returns (0, total) on success
// where total is the number of bytes forwarded; (err, total) when a
// poll_write error short-circuits. EOF on the read side is the only
// natural termination condition.
async copy(r<u64>, w<u64>) (i32, u64) {
    raw<iobuf.Buf>          = iobuf.NewBuf(COPY_DEFAULT_CAP.(i32))
    backing<iobuf.Buffer>   = iobuf.Buffer::from_uinit(raw)
    rb<aio.ReadBuf>         = aio.ReadBuf::new(backing)
    total<u64>              = 0
    loop {
        // Reset window so each iteration fills from offset 0.
        rb.filled       = 0
        backing.filled  = 0
        n<u64>          = 0
        rerr<i32>       = 0
        rerr, n         = aiou.read(r, rb).await
        if rerr != 0 return rerr, total
        if n == 0 return 0, total
        slice<iobuf.Buf> = new iobuf.Buf {
            inner: raw.inner,
            len:   n
        }
        werr<i32> = aiou.write_all(w, slice).await
        if werr != 0 return werr, total
        total = total + n
    }
}
