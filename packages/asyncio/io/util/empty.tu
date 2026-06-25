// AsyncRead source that always returns EOF (zero bytes).

use runtime
use io as iobuf
use asyncio.io as aio

// Zero-sized empty reader; impl AsyncRead returns PollReady immediately
// without filling the destination buffer.
mem Empty {
    i32 _pad   // empty mem requires at least one field for `new` to allocate
}

// Build an Empty reader.
const Empty::new() Empty {
    e<Empty> = new Empty
    e._pad = 0
    return e
}

// Convenience top-level constructor.
const empty() Empty {
    return Empty::new()
}

// Always Ready, no bytes written.
impl aio.AsyncRead for Empty {
    fn poll_read(ctx<u64>, dst<aio.ReadBuf>) i32 {
        return runtime.PollReady
    }
}

// AsyncBufRead presents an empty slice; consume() is a no-op.
impl aio.AsyncBufRead for Empty {
    fn poll_fill_buf(ctx<u64>) (i32, iobuf.Buf) {
        return runtime.PollReady, new iobuf.Buf { inner: null, len: 0 }
    }
    fn consume(amt<u64>){
    }
}
