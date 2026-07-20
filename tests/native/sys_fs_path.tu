// Formal tests for library/sys path syscalls used by asyncio.fs:
// mkdir / openat / write / close / unlink / rmdir (mother: libc/tustd).

use fmt
use os
use std
use sys
use string

fn main(){
    fmt.println("test sys fs path")
    dir_s<string.String> = string.S(*"/tmp/tu_lib_formal_sys_dir3")
    file_s<string.String> = string.S(*"/tmp/tu_lib_formal_sys_dir3/f.txt")
    dirp<i8*> = string.cstr(dir_s)
    filep<i8*> = string.cstr(file_s)
    sys.unlink(filep)
    sys.rmdir(dirp)
    mk<i32> = sys.mkdir(dirp, 493)
    flags<i64> = std.O_CREAT
    flags = flags + std.O_RDWR
    flags = flags + std.O_TRUNC
    mode<i64> = 420
    fd<i32> = sys.openat(std.AT_FDCWD, filep, flags, mode)
    if fd < 0 {
        os.dief("openat %d", fd)
    }
    msg_s<string.String> = string.S(*"hi-sys")
    wbuf<u8*> = string.cstr(msg_s)
    wn<i64> = sys.write(fd, wbuf, 6)
    sys.close(fd)
    sys.unlink(filep)
    sys.rmdir(dirp)
    fmt.println("test sys fs path success")
}
