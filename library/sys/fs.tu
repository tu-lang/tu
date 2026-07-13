
use io

mem File {
    FileDesc* fd_slot
}

File::fromrawfd(fd_val<i32>) File {
    return new File{
        fd_slot: new FileDesc{
            raw_fd: fd_val
        }
    }
}

File::read(buf<io.Buf>) i32 , u64 {
    err<i32> ,size<u64> = this.fd_slot.read_io(buf)
    return err, size
}

File::write(buf<io.Buf>) i32,u64 {
    err<i32> ,size<u64> = this.fd_slot.write_io(buf)
    return err, size
}

impl io.Read for File {
    fn read(buf<io.Buf>) i32, u64 {
        err<i32>, size<u64> = this.fd_slot.read_io(buf)
        return err, size
    }
}

impl io.Write for File {
    fn write(buf<io.Buf>) i32, u64 {
        err<i32>, size<u64> = this.fd_slot.write_io(buf)
        return err, size
    }
}

fn unlink(p<string.String>) i32 {
    return Ok
}
