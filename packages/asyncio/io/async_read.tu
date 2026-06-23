// Async read interface. Implementors fill `buf` and return PollPending
// or PollReady; partial reads are allowed (signalled by buf.filled > 0
// even when the future returns PollPending on a second poll).

use runtime

// poll_read returns one of runtime.PollPending / runtime.PollReady /
// runtime.PollError; on success the caller inspects buf.filled() to
// learn how many bytes landed.
api AsyncRead {
    fn poll_read(ctx<u64>, buf<ReadBuf>) (i32)
}
