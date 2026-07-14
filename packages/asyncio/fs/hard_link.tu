// fs_hard_link (tokio::fs::hard_link): create a hard link.

use io
use string
use sys

// Create a hard link `dst` pointing at the same inode as `src` (link(2)).
// Returns io.Ok / error.
async fs_hard_link(src<string.String>, dst<string.String>) i32 {
    err<i32>, _ = sys.cvt(sys.link(src.str(), dst.str()))
    return err
}
