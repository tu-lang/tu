// Async seek interface. Two-phase: start_seek validates input, then
// poll_complete drains the operation.

use runtime

// SeekFrom kinds. 0 = absolute offset; 1 = relative to current position;
// 2 = relative to end (offset is typically negative).
SEEK_FROM_START<i32>   = 0
SEEK_FROM_CURRENT<i32> = 1
SEEK_FROM_END<i32>     = 2

// Combined seek argument; `from` selects the origin, `offset` is signed.
mem SeekFrom {
    i32 from
    i64 offset
}

// Build a SeekFrom for an absolute offset.
const SeekFrom::start(off<i64>) SeekFrom {
    s<SeekFrom> = new SeekFrom
    s.from   = SEEK_FROM_START
    s.offset = off
    return s
}

// Build a SeekFrom relative to the current position.
const SeekFrom::current(off<i64>) SeekFrom {
    s<SeekFrom> = new SeekFrom
    s.from   = SEEK_FROM_CURRENT
    s.offset = off
    return s
}

// Build a SeekFrom relative to the end (offset typically negative).
const SeekFrom::end(off<i64>) SeekFrom {
    s<SeekFrom> = new SeekFrom
    s.from   = SEEK_FROM_END
    s.offset = off
    return s
}

// Two-phase async seek: start_seek records the request, poll_complete
// drains it (returning the new absolute offset on Ready).
api AsyncSeek {
    fn start_seek(pos<SeekFrom>) i32
    fn poll_complete(ctx<u64>) (i32, u64)
}
