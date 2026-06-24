// Split a single AsyncRead+AsyncWrite source into two independent halves
// that can be awaited in different tasks. The two halves share the same
// backing object (stored as raw bits in `inner`); callers must ensure
// the backing outlives both halves.

use io as iobuf

// Read-side view over a shared AsyncRead+AsyncWrite source.
mem ReadHalf {
    u64 inner    // raw bits of backing object; cast via inner.(AsyncRead) on use
}

// Write-side view over the same backing object as a paired ReadHalf.
mem WriteHalf {
    u64 inner    // raw bits of backing object; cast via inner.(AsyncWrite) on use
}

// Wrap a backing object's raw bits in a ReadHalf.
const ReadHalf::new(inner<u64>) ReadHalf {
    rh<ReadHalf> = new ReadHalf
    rh.inner = inner
    return rh
}

// Wrap a backing object's raw bits in a WriteHalf.
const WriteHalf::new(inner<u64>) WriteHalf {
    wh<WriteHalf> = new WriteHalf
    wh.inner = inner
    return wh
}

// Forward poll_read to the backing object via api dispatch.
impl AsyncRead for ReadHalf {
    fn poll_read(ctx<u64>, buf<ReadBuf>) i32 {
        return this.inner.(AsyncRead).poll_read(ctx, buf)
    }
}

// Forward all write-side ops to the backing object via api dispatch.
impl AsyncWrite for WriteHalf {
    fn poll_write(ctx<u64>, buf<iobuf.Buf>) (i32, u64) {
        return this.inner.(AsyncWrite).poll_write(ctx, buf)
    }
    fn poll_flush(ctx<u64>) i32 {
        return this.inner.(AsyncWrite).poll_flush(ctx)
    }
    fn poll_shutdown(ctx<u64>) i32 {
        return this.inner.(AsyncWrite).poll_shutdown(ctx)
    }
}

// Build a (ReadHalf, WriteHalf) pair sharing one backing object. `rw` is
// the raw bits of any value that implements both AsyncRead and AsyncWrite;
// callers cast via obj.(u64) at the call site.
const split(rw<u64>) (ReadHalf, WriteHalf) {
    return ReadHalf::new(rw), WriteHalf::new(rw)
}
