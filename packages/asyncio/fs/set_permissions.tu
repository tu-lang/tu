// fs_set_permissions (tokio::fs::set_permissions): chmod a path.

use io
use string
use sys
use runtime

mem SetPermissionsFut: async {
    u64 path_bits
    u32 mode
}

SetPermissionsFut::poll(ctx) {
    mode_u<u32> = this.mode
    pc<i8*> = string.cstr_from_bits(this.path_bits)
    err<i32>, junk<u64> = sys.cvt(sys.chmod(pc, mode_u.(i64)))
    return runtime.PollReady, err
}

fn fs_set_permissions(path_bits<u64>, mode<u32>) SetPermissionsFut {
    return new SetPermissionsFut { path_bits: path_bits, mode: mode }
}
