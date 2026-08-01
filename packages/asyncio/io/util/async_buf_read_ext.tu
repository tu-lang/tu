// AsyncBufRead extension stubs (fill_buf / Split / Lines).

use runtime
use io
use asyncio.io as aio

LF<u8> = 10

mem FillBuf: async {
    u64 r
}

const FillBuf::new(r<u64>) FillBuf {
    f<FillBuf> = new FillBuf
    f.r = r
    return f
}

FillBuf::poll(ctx) {
    empty<io.Buf> = new io.Buf
    empty.data_ptr = null
    empty.byte_len = 0
    ok<i32> = 0
    return runtime.PollReady, ok, empty
}

fn fill_buf(r<u64>) FillBuf {
    return FillBuf::new(r)
}

mem Split {
    u64 r
    u8  delim
    i32 done
}

const Split::new(r<u64>, delim<u8>) Split {
    s<Split> = new Split
    s.r = r
    s.delim = delim
    s.done = 0
    return s
}

mem Lines {
    u64 r
    i32 done
}

const Lines::new(r<u64>) Lines {
    l<Lines> = new Lines
    l.r = r
    l.done = 0
    return l
}

mem SplitNext: async {
    u64 r
}

const SplitNext::new(r<u64>) SplitNext {
    f<SplitNext> = new SplitNext
    f.r = r
    return f
}

SplitNext::poll(ctx) {
    unsupported<i32> = 95
    zero<u64> = 0.(u64)
    return runtime.PollReady, unsupported, zero
}

fn split_next(s<Split>, dst<aio.ReadBuf>) SplitNext {
    return SplitNext::new(s.r)
}

mem LinesNext: async {
    u64 r
}

const LinesNext::new(r<u64>) LinesNext {
    f<LinesNext> = new LinesNext
    f.r = r
    return f
}

LinesNext::poll(ctx) {
    unsupported<i32> = 95
    zero<u64> = 0.(u64)
    return runtime.PollReady, unsupported, zero
}

fn lines_next_line(l<Lines>, dst<aio.ReadBuf>) LinesNext {
    return LinesNext::new(l.r)
}
