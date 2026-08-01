// fs_set_permissions: chmod a path.

use io
use string
use sys
use runtime

mem SetPermissionsFut: async {
    string.String path
    u32 mode
}

SetPermissionsFut::poll(ctx) {
    mode_u<u32> = this.mode
    pc<i8*> = string.cstr(this.path)
    err<i32>, junk<u64> = sys.cvt(sys.chmod(pc, mode_u.(i64)))
    return runtime.PollReady, err
}

fn fs_set_permissions(path<string.String>, mode<u32>) SetPermissionsFut {
    return new SetPermissionsFut { path: path, mode: mode }
}
