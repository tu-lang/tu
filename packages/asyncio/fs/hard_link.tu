// fs_hard_link: create a hard link.

use io
use string
use sys
use runtime

mem HardLinkFut: async {
    u64 src_bits
    u64 dst_bits
}

HardLinkFut::poll(ctx) {
    src_c<i8*> = string.cstr_from_bits(this.src_bits)
    dst_c<i8*> = string.cstr_from_bits(this.dst_bits)
    err<i32>, junk<u64> = sys.cvt(sys.link(src_c, dst_c))
    return runtime.PollReady, err
}

fn fs_hard_link(src_bits<u64>, dst_bits<u64>) HardLinkFut {
    return new HardLinkFut { src_bits: src_bits, dst_bits: dst_bits }
}
