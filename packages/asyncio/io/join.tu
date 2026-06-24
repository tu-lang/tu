// Combine an AsyncRead source and an AsyncWrite sink into a single value
// that implements both apis. The inverse of `split`; useful when adapter
// code needs a unified read+write handle.

use io as iobuf

// Joined read+write handle. Stores the two backing objects' raw bits;
// callers must ensure both backings outlive the IoJoin.
mem IoJoin {
    u64 r   // raw bits of the AsyncRead backing
    u64 w   // raw bits of the AsyncWrite backing
}

// Build an IoJoin from an AsyncRead source and AsyncWrite sink, both
// passed as raw bits (cast via obj.(u64) at the call site).
const IoJoin::new(r<u64>, w<u64>) IoJoin {
    j<IoJoin> = new IoJoin
    j.r = r
    j.w = w
    return j
}

// Forward poll_read to the AsyncRead backing via api dispatch.
impl AsyncRead for IoJoin {
    fn poll_read(ctx<u64>, buf<ReadBuf>) i32 {
        return this.r.(AsyncRead).poll_read(ctx, buf)
    }
}

// Forward all write-side ops to the AsyncWrite backing via api dispatch.
impl AsyncWrite for IoJoin {
    fn poll_write(ctx<u64>, buf<iobuf.Buf>) (i32, u64) {
        return this.w.(AsyncWrite).poll_write(ctx, buf)
    }
    fn poll_flush(ctx<u64>) i32 {
        return this.w.(AsyncWrite).poll_flush(ctx)
    }
    fn poll_shutdown(ctx<u64>) i32 {
        return this.w.(AsyncWrite).poll_shutdown(ctx)
    }
}

// Free function alias matching split()'s pairing style.
const join(r<u64>, w<u64>) IoJoin {
    return IoJoin::new(r, w)
}
