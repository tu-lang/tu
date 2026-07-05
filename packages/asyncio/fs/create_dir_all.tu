// fs_create_dir_all (tokio::fs::create_dir_all): create `path` and every
// missing parent, treating already-existing components as success.

use io
use string
use sys

// mkdir that tolerates an existing directory. Returns io.Ok on create or when
// the component already exists; propagates any other error.
fn mkdir_ok_exists(path<string.String>) i32 {
    err<i32>, _ = sys.cvt(sys_mkdir(path.str(), 511))
    if err == io.Ok return io.Ok
    if err == io.AlreadyExists return io.Ok
    return err
}

// Create `path` recursively. Walks each "/"-separated prefix and mkdirs it.
// Returns io.Ok, io.InvalidInput for an empty path, or the first hard error.
async fs_create_dir_all(path<string.String>) i32 {
    len<i32> = path.len()
    if len == 0 return io.InvalidInput
    p<u8*> = path.str()
    i<i32> = 0
    if p[0] == '/' i = 1
    while i <= len {
        if i == len || p[i] == '/' {
            if i > 0 {
                prefix<string.String> = path.sub(0, i.(i64))
                merr<i32> = mkdir_ok_exists(prefix)
                if merr != io.Ok return merr
            }
        }
        i += 1
    }
    return io.Ok
}
