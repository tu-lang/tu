// AsyncRead extension helpers. `Read` is a leaf future for one
// poll_read call. Package-level async must only return the leaf (no await).

use runtime
use asyncio.io as aio

// Leaf future for a single AsyncRead::poll_read call. PollReady payload
 // is (err, n_delta) matching int_tcp_echo `rerr, n = read(...).await`.
mem Read: async {
    u64          r
    aio.ReadBuf* buf
    u64          start
    i32          started
}

const Read::new(r<u64>, buf<aio.ReadBuf>) Read {
    f<Read> = new Read
    f.r = r
    f.buf = buf
    f.start = 0
    f.started = 0
    return f
}

Read::poll(ctx) {
    if this.started == 0 {
        this.start = this.buf.filled_len()
        this.started = 1
    }
    err<i32> = this.r.(aio.AsyncRead).poll_read(ctx, this.buf)
    if err == runtime.PollPending {
        return runtime.PollPending
    }
    if err == runtime.PollError {
        other_err<i32> = 1
        zero<u64> = 0.(u64)
        return runtime.PollReady, other_err, zero
    }
    delta<u64> = this.buf.filled_len() - this.start
    return runtime.PollReady, 0.(i64), delta
}

// The design read(): sync factory returning Read leaf; callers `.await` for (err, n).
fn read(r<u64>, buf<aio.ReadBuf>) Read {
    return Read::new(r, buf)
}
