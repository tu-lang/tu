// fs_hard_link: create a hard link.

use io
use string
use sys
use runtime

mem HardLinkFut: async {
    string.String src
    string.String dst
}

HardLinkFut::poll(ctx) {
    src_c<i8*> = string.cstr(this.src)
    dst_c<i8*> = string.cstr(this.dst)
    err<i32>, junk<u64> = sys.cvt(sys.link(src_c, dst_c))
    return runtime.PollReady, err
}

fn fs_hard_link(src<string.String>, dst<string.String>) HardLinkFut {
    return new HardLinkFut {
        src: src,
        dst: dst
    }
}
