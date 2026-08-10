// Mixed fn + func callers → no-body sys.* register ABI with literal args.

use fmt
use os
use std
use sys
use string

fn static_mkdir_write(){
    fmt.println("test mixed asm register argcast fn")
    dir_s<string.String> = string.S(*"/tmp/tu_asm_argcast_mixed_fn_dir")
    file_s<string.String> = string.S(*"/tmp/tu_asm_argcast_mixed_fn_dir/f.txt")
    dirp<i8*> = string.cstr(dir_s)
    filep<i8*> = string.cstr(file_s)
    sys.unlink(filep)
    sys.rmdir(dirp)
    mk<i32> = sys.mkdir(dirp, 493.(i64))
    if mk != 0 {
        os.die("mixed fn mkdir typeassert failed")
    }
    flags<i64> = std.O_CREAT
    flags = flags + std.O_RDWR
    flags = flags + std.O_TRUNC
    mode<i64> = 420
    fd<i32> = sys.openat(std.AT_FDCWD, filep, flags, mode)
    if fd < 0 {
        os.die("mixed fn openat failed")
    }
    msg_s<string.String> = string.S(*"hi-mix")
    wbuf<u8*> = string.cstr(msg_s)
    nlen<u64> = 3
    nlen = nlen + 3
    wrote_n<i64> = sys.write(fd, wbuf, nlen)
    if wrote_n != 6 {
        os.die("mixed fn write typed local failed")
    }
    sys.close(fd)
    fd = sys.openat(std.AT_FDCWD, filep, flags, mode)
    if fd < 0 {
        os.die("mixed fn openat 2 failed")
    }
    wrote_n = sys.write(fd, wbuf, 6)
    if wrote_n != 6 {
        os.die("mixed fn write literal 6 failed")
    }
    sys.close(fd)
    sys.unlink(filep)
    sys.rmdir(dirp)
    fmt.println("test mixed asm register argcast fn success")
}

func dyn_mkdir_literal(){
    fmt.println("test mixed asm register argcast func")
    dir_s<string.String> = string.S(*"/tmp/tu_asm_argcast_mixed_func_dir")
    dirp<i8*> = string.cstr(dir_s)
    sys.rmdir(dirp)
    mk<i32> = sys.mkdir(dirp, 493)
    if mk != 0 {
        os.die("mixed func mkdir literal failed")
    }
    sys.rmdir(dirp)
    fmt.println("test mixed asm register argcast func success")
}

fn main(){
    static_mkdir_write()
    dyn_mkdir_literal()
}
