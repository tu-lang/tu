// fs_remove_file (tokio::fs::remove_file): unlink a file.

use io
use string
use sys

// Remove the file `path` (unlink). Returns io.Ok / error.
async fs_remove_file(path<string.String>) i32 {
    err<i32>, _ = sys.cvt(sys_unlink(path.str()))
    return err
}
