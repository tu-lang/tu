// fs_remove_dir_all: recursively delete a directory
// and everything under it.

use std
use io
use string
use sys
use runtime

// Join dir/name into a fresh cstr buffer.
fn join_path_cstr(dir_c<i8*>, name_c<i8*>) i8* {
    dlen_u<u64> = std.strlen(dir_c)
    nlen_u<u64> = std.strlen(name_c)
    dlen<i32> = dlen_u.(i32)
    nlen<i32> = nlen_u.(i32)
    alloc_n<i32> = dlen + nlen + 2
    out<i8*> = new alloc_n
    std.memcpy(out, dir_c, dlen_u)
    slash_p<i8*> = out + dlen
    *slash_p = '/'
    std.memcpy(out + dlen + 1, name_c, nlen_u)
    end_p<i8*> = out + dlen + nlen + 1
    *end_p = 0
    return out
}

// stat(2) directory check.
fn path_is_dir_cstr(path_c<i8*>) i32 {
    s<std.Stat> = new std.Stat
    eraw<i32> = 0
    eraw = sys.stat(path_c, s.(u64))
    if eraw < 0 return 0
    mode_u<u32> = s.st_mode
    mode_i<i64> = mode_u.(i64)
    ifmt<i64> = 61440
    ifdir<i64> = 16384
    if (mode_i & ifmt) == ifdir return 1
    return 0
}

// Map negative errno to io error; non-negative => Ok.
fn fs_sys_ret(raw<i32>) i32 {
    ok_code<i32> = io.Ok
    if raw >= 0 return ok_code
    err<i32>, junk<u64> = sys.cvt(raw)
    return err
}

// Sync recursive remove.
fn remove_dir_all_sync(path_c<i8*>) i32 {
    ok_code<i32> = io.Ok
    pc<i8*> = path_c
    raw_rm<i32> = 0
    raw_rm = sys.rmdir(pc)
    if raw_rm >= 0 return ok_code

    rerr<i32>, rd<ReadDir> = read_dir_open_sync(path_c)
    if rerr != ok_code return rerr

    loop {
        nerr<i32>, name<string.String> = read_dir_next(rd)
        if nerr != ok_code {
            rd.close()
            return nerr
        }
        if name == null {
            break
        }
        name_c<i8*> = string.cstr(name)
        child_c<i8*> = join_path_cstr(pc, name_c)
        if path_is_dir_cstr(child_c) != 0 {
            cerr<i32> = remove_dir_all_sync(child_c)
            if cerr != ok_code {
                rd.close()
                return cerr
            }
        } else {
            uraw<i32> = 0
            uraw = sys.unlink(child_c)
            uerr<i32> = fs_sys_ret(uraw)
            if uerr != ok_code {
                rd.close()
                return uerr
            }
        }
    }
    rd.close()
    raw_rm = 0
    raw_rm = sys.rmdir(pc)
    return fs_sys_ret(raw_rm)
}

mem RemoveDirAllFut: async {
    string.String path
    u64 pad
}

RemoveDirAllFut::poll(ctx) {
    err<i32> = remove_dir_all_sync(string.cstr(this.path))
    ready<i32> = runtime.PollReady
    return ready, err
}

fn fs_remove_dir_all(path<string.String>) RemoveDirAllFut {
    return new RemoveDirAllFut { path: path, pad: 0 }
}
