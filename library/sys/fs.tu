
use io

mem File {
    FileDesc* fd
}

File::fromrawfd(fd<i32>) File {
    
    return new File{
        fd: new FileDesc{
            fd: fd
        }
    }
}

File::read(buf<io.Buffer>) i32 , u64 {
    err<i32> ,size<u64> = this.fd.read(buf)
    return err, size
}

File::write(buf<io.Buffer>) i32,u64 {
    err<i32> ,size<u64> = this.fd.write(buf)
    return err, size
}

impl io.Read for File {
    fn read(buf<io.Buffer>) i32, u64 {
        err<i32> , size<u64> = this.fd.read(buf)
    }
}
//NOTICE-PANIC
impl io.Write for File {
    fn write(buf<io.Buffer>) i32, u64 {
        err<i32> , size<u64> = this.fd.write(buf)
        return err,size
    }
}

fn unlink(p<string.String>) i32 {
    return run_path_with_cstr(p, fn(p) {
        //TODO:
            err<i32> , ret<u64> = cvt(sys_unlink(p))
            return err ,ret
        }
    )
}
