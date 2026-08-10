// Dynamic class/func caller → no-body sys.* (register ABI).
// Literals must go through argCast (mov $n), not newobject.

use fmt
use os
use std
use sys
use string

class AsmFs {
    func init(){}
}

AsmFs::run(){
    fmt.println("test class asm register argcast")
    dir_s<string.String> = string.S(*"/tmp/tu_asm_argcast_class_dir")
    file_s<string.String> = string.S(*"/tmp/tu_asm_argcast_class_dir/f.txt")
    dirp<i8*> = string.cstr(dir_s)
    filep<i8*> = string.cstr(file_s)
    sys.unlink(filep)
    sys.rmdir(dirp)
    mk<i32> = sys.mkdir(dirp, 493)
    if mk != 0 {
        os.die("class mkdir literal 493 failed")
    }
    flags<i64> = std.O_CREAT
    flags = flags + std.O_RDWR
    flags = flags + std.O_TRUNC
    mode<i64> = 420
    fd<i32> = sys.openat(std.AT_FDCWD, filep, flags, mode)
    if fd < 0 {
        os.die("class openat failed")
    }
    msg_s<string.String> = string.S(*"hi-cls")
    wbuf<u8*> = string.cstr(msg_s)
    wrote_n<i64> = sys.write(fd, wbuf, 6)
    if wrote_n != 6 {
        os.die("class write literal 6 failed")
    }
    sys.close(fd)
    sys.unlink(filep)
    sys.rmdir(dirp)
    k0<i32> = sys.kill(1, 0)
    if k0 > 0 {
        os.die("class kill(1,0) unexpected")
    }
    fmt.println("test class asm register argcast success")
}

func dyn_mkdir_literal(){
    dir_s<string.String> = string.S(*"/tmp/tu_asm_argcast_func_dir")
    dirp<i8*> = string.cstr(dir_s)
    sys.rmdir(dirp)
    extra<i64> = 400
    extra = extra + 93
    mk<i32> = sys.mkdir(dirp, extra)
    if mk != 0 {
        os.die("func mkdir typed local failed")
    }
    sys.rmdir(dirp)
}

func main(){
    dyn_mkdir_literal()
    new AsmFs().run()
}
