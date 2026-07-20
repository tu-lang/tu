// fs_symlink (tokio::fs::symlink): create a symbolic link.

use io
use string
use sys
use runtime

mem SymlinkFut: async {
    u64 src_bits
    u64 dst_bits
}

SymlinkFut::poll(ctx) {
    src_c<i8*> = string.cstr_from_bits(this.src_bits)
    dst_c<i8*> = string.cstr_from_bits(this.dst_bits)
    err<i32>, junk<u64> = sys.cvt(sys.symlink(src_c, dst_c))
    return runtime.PollReady, err
}

fn fs_symlink(src_bits<u64>, dst_bits<u64>) SymlinkFut {
    return new SymlinkFut { src_bits: src_bits, dst_bits: dst_bits }
}
