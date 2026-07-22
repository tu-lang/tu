// AsyncSeek extension stub.

use runtime
use asyncio.io as aio

mem SeekComplete: async {
    u64 s
}

const SeekComplete::new(s<u64>, pos<aio.SeekFrom>) SeekComplete {
    f<SeekComplete> = new SeekComplete
    f.s = s
    return f
}

SeekComplete::poll(ctx) {
    return runtime.PollReady, 0.(i64), 0.(u64)
}

fn seek(s<u64>, pos<aio.SeekFrom>) SeekComplete {
    return SeekComplete::new(s, pos)
}
