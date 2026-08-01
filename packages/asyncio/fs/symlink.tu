// fs_symlink: create a symbolic link.

use io
use string
use sys
use runtime

mem SymlinkFut: async {
    string.String src
    string.String dst
}

SymlinkFut::poll(ctx) {
    src_c<i8*> = string.cstr(this.src)
    dst_c<i8*> = string.cstr(this.dst)
    err<i32>, junk<u64> = sys.cvt(sys.symlink(src_c, dst_c))
    return runtime.PollReady, err
}

fn fs_symlink(src<string.String>, dst<string.String>) SymlinkFut {
    return new SymlinkFut {
        src: src,
        dst: dst
    }
}
