
use io

mem File {
    FileDesc* fd_slot
}

// Mother: File::fromrawfd — const for Type::method static calls.
const File::fromrawfd(fd_val<i32>) File {
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

File::close() {
    this.fd_slot.close_io()
}

// Cross-package bridges: netio holds File as u64 bits (mem body can't embed pkg.File).
fn file_fromrawfd_raw(fd_val<i32>) u64 {
    f<File> = File::fromrawfd(fd_val)
    return f.(u64)
}

fn file_write_raw(bits<u64>, buf<io.Buf>) i32, u64 {
    f<File> = bits.(File)
    err<i32>, size<u64> = f.write(buf)
    return err, size
}

fn file_read_raw(bits<u64>, buf<io.Buf>) i32, u64 {
    f<File> = bits.(File)
    err<i32>, size<u64> = f.read(buf)
    return err, size
}

fn file_close_raw(bits<u64>) {
    f<File> = bits.(File)
    f.close()
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
    fn flush() i32 {
        return Ok
    }
}

// Path unlink lives in sys.tu as fn unlink(path<i8*>) → sys_unlink asm.
