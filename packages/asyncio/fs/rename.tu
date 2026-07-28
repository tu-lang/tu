// fs_rename: rename/move a path.
// Leaf future pattern: sync factory + poll, no await body.

use io
use string
use sys
use runtime

// Leaf: rename(2) on first poll.
mem RenameFut: async {
    u64 from_bits
    u64 to_bits
}

RenameFut::poll(ctx) {
    from_c<i8*> = string.cstr_from_bits(this.from_bits)
    to_c<i8*> = string.cstr_from_bits(this.to_bits)
    err<i32>, junk<u64> = sys.cvt(sys.rename(from_c, to_c))
    return runtime.PollReady, err
}

// Returns erased Future for `.await`.
fn fs_rename(from<string.String>, to<string.String>) runtime.Future {
    f<RenameFut> = new RenameFut {
        from_bits: string.string_to_bits(from),
        to_bits: string.string_to_bits(to)
    }
    fut<runtime.Future> = f
    return fut
}
