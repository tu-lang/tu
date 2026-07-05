// fs_try_exists (tokio::fs::try_exists): test whether a path exists.

use std
use io
use string
use sys

// Returns (io.Ok, true) if `path` exists, (io.Ok, false) if it definitively
// does not (stat NotFound), and (err, false) for any other error (e.g.
// permission denied on a parent) which the caller must not read as absence.
async fs_try_exists(path<string.String>) i32, bool {
    s<std.Stat> = new std.Stat
    err<i32>, _ = sys.cvt(sys_stat(path.str(), s))
    if err == io.Ok return io.Ok, true
    if err == io.NotFound return io.Ok, false
    return err, false
}
