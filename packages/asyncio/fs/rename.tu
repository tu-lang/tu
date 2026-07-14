// fs_rename (tokio::fs::rename): rename/move a path.

use io
use string
use sys

// Rename `from` to `to` (rename(2)). Replaces `to` if it exists and is
// compatible. Returns io.Ok / error.
async fs_rename(from<string.String>, to<string.String>) i32 {
    err<i32>, _ = sys.cvt(sys.rename(from.str(), to.str()))
    return err
}
