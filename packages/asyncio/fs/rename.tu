// fs_rename: rename/move a path.
// Leaf future pattern: sync factory + poll, no await body.

use io
use string
use sys
use runtime

// Leaf: rename(2) on first poll.
mem RenameFut: async {
    string.String from
    string.String to
}

RenameFut::poll(ctx) {
    from_c<i8*> = string.cstr(this.from)
    to_c<i8*> = string.cstr(this.to)
    err<i32>, junk<u64> = sys.cvt(sys.rename(from_c, to_c))
    return runtime.PollReady, err
}

// Returns concrete RenameFut for `.await`.
fn fs_rename(from<string.String>, to<string.String>) RenameFut {
    return new RenameFut {
        from: from,
        to: to
    }
}
