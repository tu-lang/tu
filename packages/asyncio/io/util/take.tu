// AsyncRead adapter that yields at most `limit` bytes from the inner
// source, then signals EOF.

use runtime
use io as iobuf
use asyncio.io as aio

// `inner` is the raw bits of an AsyncRead implementor; `limit` is the
// remaining byte budget. When limit reaches 0 the adapter stops
// polling the source and returns EOF.
mem Take {
    u64 inner   // raw bits of an AsyncRead implementor
    u64 limit
}

// Build a Take that exposes at most `limit` bytes from `inner`.
const Take::new(inner<u64>, limit<u64>) Take {
    t<Take> = new Take
    t.inner = inner
    t.limit = limit
    return t
}

// Bytes still available before this Take signals EOF.
Take::limit_remaining() u64 {
    return this.limit
}

// AsyncRead: clamp the destination's remaining capacity to `limit`,
// drive one poll_read, then debit the bytes that landed.
impl aio.AsyncRead for Take {
    fn poll_read(ctx<u64>, dst<aio.ReadBuf>) i32 {
        if this.limit == 0 return runtime.PollReady
        // Reserve a temporary view that limits how much the inner
        // reader can fill on this turn.
        before<u64> = dst.filled_len()
        room<u64>   = dst.remaining()
        cap<u64>    = room
        if this.limit < cap cap = this.limit
        // Build a sub-Buffer whose capacity equals `cap`. Easiest is
        // to swap the parent's filled cursor: the inner source's
        // poll_read sees `cap` bytes of remaining space.
        original_cap<u64> = dst.inner.buf.len
        dst.inner.buf.len = before + cap
        err<i32> = this.inner.(aio.AsyncRead).poll_read(ctx, dst)
        dst.inner.buf.len = original_cap
        if err == runtime.PollPending return runtime.PollPending
        if err == runtime.PollError   return runtime.PollError
        delta<u64> = dst.filled_len() - before
        this.limit = this.limit - delta
        return runtime.PollReady
    }
}
