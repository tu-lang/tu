// Async buffered-read interface. Layered on AsyncRead — implementors
// expose poll_fill_buf for callers that want to peek without copying,
// then consume(amt) when the bytes are taken.

use runtime
use io as iobuf

// Implementors typically wrap an AsyncRead source plus an internal
// io.buffer.Buffer; default poll_fill_buf returns an empty Buf.
api AsyncBufRead : AsyncRead {
    fn poll_fill_buf(ctx<u64>) (i32, iobuf.Buf) {
        return runtime.PollReady, new iobuf.Buf { inner: null, len: 0 }
    }
    fn consume(amt<u64>)
}
