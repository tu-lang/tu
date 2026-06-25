// AsyncSeek extension helpers. `seek` packages start_seek + a busy-poll
// loop over poll_complete into a single await point.

use runtime
use io as iobuf
use asyncio.io as aio

// Leaf future driving an in-progress AsyncSeek. start_seek has already
// been called by `seek`; `s` only loops on poll_complete until the
// implementor returns Ready or Error.
mem SeekComplete: async {
    u64 s         // raw bits of an AsyncSeek implementor
    u64 pos       // resolved absolute offset on Ready
    i32 err       // 0 = Ok, iobuf.Other on PollError
}

// Build a SeekComplete leaf for seeker `s`.
const SeekComplete::new(s<u64>) SeekComplete {
    f<SeekComplete> = new SeekComplete
    f.s   = s
    f.pos = 0
    f.err = 0
    return f
}

// Drive one poll_complete. PollPending propagates; PollReady stores
// the offset on this; PollError latches err = iobuf.Other.
SeekComplete::poll(ctx) {
    err<i32>, pos<u64> = this.s.(aio.AsyncSeek).poll_complete(ctx)
    if err == runtime.PollPending {
        return runtime.PollPending
    }
    if err == runtime.PollError {
        this.err = iobuf.Other
        return runtime.PollReady, 0.(u64)
    }
    this.pos = pos
    return runtime.PollReady, 0.(u64)
}

// Seek `s` to `pos` and resolve the absolute offset. Returns:
//   (0, off) on success;
//   (start_err, 0) when start_seek rejected the request;
//   (iobuf.Other, 0) when poll_complete surfaced an error after start.
async seek(s<u64>, pos<aio.SeekFrom>) (i32, u64) {
    start_err<i32> = s.(aio.AsyncSeek).start_seek(pos)
    if start_err != 0 return start_err, 0.(u64)
    fut<SeekComplete> = SeekComplete::new(s)
    fut.await
    if fut.err != 0 return fut.err, 0.(u64)
    return 0, fut.pos
}
