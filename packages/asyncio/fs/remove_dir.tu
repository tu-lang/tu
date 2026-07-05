// fs_remove_dir (tokio::fs::remove_dir): remove an empty directory.

use io
use string
use sys

// Remove the empty directory `path` (rmdir). Fails with io.DirectoryNotEmpty
// when it still has entries.
async fs_remove_dir(path<string.String>) i32 {
    err<i32>, _ = sys.cvt(sys_rmdir(path.str()))
    return err
}
