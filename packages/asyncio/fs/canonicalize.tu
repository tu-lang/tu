// fs_canonicalize (tokio::fs::canonicalize).
//
// V1 is a best-effort resolver: it readlinks a terminal symlink and otherwise
// returns the input path unchanged. It does NOT normalize "."/".." components
// or resolve to an absolute path (Linux has no realpath syscall; a full
// component-by-component resolver is deferred). Callers needing true
// canonicalization should treat this as a placeholder.

use io
use string
use sys

// Resolve `path`. If it is a symlink, returns its target; if it is a regular
// path (readlink EINVAL), returns a copy of the input. Returns (err, null) on
// any other failure.
async fs_canonicalize(path<string.String>) i32, string.String {
    buf<u8*> = new 4096
    err<i32>, n<u64> = sys.cvt(sys_readlink(path.str(), buf, 4096))
    if err == io.Ok {
        return io.Ok, new string.String { inner: string.newlen(buf, n) }
    }
    if err == io.InvalidInput {
        return io.Ok, path.dup()
    }
    return err, null
}
