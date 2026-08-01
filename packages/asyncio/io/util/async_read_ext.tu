// AsyncRead extension helpers. `Read` is a leaf future for one
// poll_read call. Package-level async must only return the leaf (no await).
//
// Leaf futures hold `aio.AsyncRead*` / `aio.ReadBuf*` (RFC: api members
// must be pointers). Bind via `new Read { ... }` literal — post-new
// field assign to Api* overwrites the async poll virf.

use runtime
use io
use asyncio.io as aio

mem Read: async {
    aio.AsyncRead* r
    aio.ReadBuf* buf
    u64 start
    i32 started
}

const Read::new(r<aio.AsyncRead>, buf<aio.ReadBuf>) Read {
    rbits<u64> = 0
    rbits = r
    bbits<u64> = aio.read_buf_to_bits(buf)
    return new Read {
        r: rbits.(aio.AsyncRead),
        buf: bbits.(aio.ReadBuf),
        start: 0.(u64),
        started: 0
    }
}

Read::poll(ctx) {
    rb<aio.ReadBuf> = this.buf
    if this.started == 0 {
        this.start = rb.filled_len()
        this.started = 1
    }
    err<i32> = this.r.poll_read(ctx, rb)
    if err == runtime.PollPending {
        return runtime.PollPending
    }
    if err == runtime.PollError {
        other_err<i32> = io.Uncategorized
        zero<u64> = 0.(u64)
        return runtime.PollReady, other_err, zero
    }
    delta<u64> = rb.filled_len() - this.start
    ok_code<i32> = io.Ok
    return runtime.PollReady, ok_code, delta
}

fn read(r<aio.AsyncRead>, buf<aio.ReadBuf>) Read {
    return Read::new(r, buf)
}

// Build ReadBuf over an io.Buf.
fn read_buf_over(buf<io.Buf>) aio.ReadBuf {
    return aio.read_buf_from_i8(io.buf_ptr(buf), io.buf_len(buf))
}
