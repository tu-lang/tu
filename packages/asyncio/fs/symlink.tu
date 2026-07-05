// fs_symlink (tokio::fs::symlink): create a symbolic link.

use io
use string
use sys

// Create a symlink `dst` whose target is `src` (symlink(2)). `src` is stored
// verbatim and is not required to exist. Returns io.Ok / error.
async fs_symlink(src<string.String>, dst<string.String>) i32 {
    err<i32>, _ = sys.cvt(sys_symlink(src.str(), dst.str()))
    return err
}
