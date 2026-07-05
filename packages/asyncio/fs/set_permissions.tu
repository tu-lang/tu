// fs_set_permissions (tokio::fs::set_permissions): chmod a path.

use io
use string
use sys

// Set the permission bits of `path` to `mode` (chmod(2)). Returns io.Ok /
// error.
async fs_set_permissions(path<string.String>, mode<u32>) i32 {
    err<i32>, _ = sys.cvt(sys_chmod(path.str(), mode.(i64)))
    return err
}
