// fs_create_dir (tokio::fs::create_dir): create a single directory (mkdir).

use io
use string
use sys

// Create the directory `path` with mode 0o777 (subject to umask). Fails with
// io.AlreadyExists if it exists and io.NotFound if a parent is missing.
async fs_create_dir(path<string.String>) i32 {
    err<i32>, _ = sys.cvt(sys_mkdir(path.str(), 511))
    return err
}
