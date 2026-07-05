// fs_remove_dir_all (tokio::fs::remove_dir_all): recursively delete a directory
// and everything under it.

use io
use string
use sys

// Join `dir` and `name` with a single "/". Assumes dir has no trailing slash.
fn join_path(dir<string.String>, name<string.String>) string.String {
    out<string.String> = dir.dup()
    out.catstr(*"/")
    out.cat(name)
    return out
}

// Recursively remove `path`. Iterates the directory, recursing into
// subdirectories and unlinking files, then rmdirs the (now empty) directory.
// Returns io.Ok or the first error. Relies on the getdents d_type hint; on
// filesystems that report DT_UNKNOWN a directory child is treated as a file
// and the final rmdir surfaces the resulting error.
async fs_remove_dir_all(path<string.String>) i32 {
    rerr<i32>, rd<ReadDir> = fs_read_dir(path).await
    if rerr != io.Ok return rerr
    loop {
        nerr<i32>, ent<DirEntry> = rd.next_entry().await
        if nerr != io.Ok {
            rd.close()
            return nerr
        }
        if ent == null break
        child<string.String> = join_path(path, ent.file_name())
        if ent.is_dir() {
            cerr<i32> = fs_remove_dir_all(child).await
            if cerr != io.Ok {
                rd.close()
                return cerr
            }
        } else {
            uerr<i32>, _ = sys.cvt(sys_unlink(child.str()))
            if uerr != io.Ok {
                rd.close()
                return uerr
            }
        }
    }
    rd.close()
    derr<i32>, _ = sys.cvt(sys_rmdir(path.str()))
    return derr
}
