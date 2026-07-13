use io

mem FileDesc {
    i32 raw_fd
}

READ_LIMIT<u64> = 18446744073709551615
UIO_MAXIOV<i32> = 1024
F_DUPFD_CLOEXEC<i32> = 1030

fn max_iov() u64 {
    return UIO_MAXIOV
}

FileDesc::try_clone() i32 ,FileDesc {
    fd_val<i32> = this.raw_fd
    err<i32>, new_fd<i32> = cvt(sys_fcntl(fd_val, F_DUPFD_CLOEXEC, 3))
    if err != Ok return err
    return Ok, new FileDesc { raw_fd: new_fd }
}

FileDesc::from_raw_fd(fd_val<i32>) FileDesc {
    if fd_val == 0xFFFFFFFF.(i32) {
        runtime.printf("fd is u32 max\n")
        os.die(1)
    }
    return new FileDesc { raw_fd: fd_val }
}

FileDesc::read_io(buf<io.Buf>) i32,u64 {
    err<i32>, ret<i64> = cvt(sys_read(this.raw_fd, buf.ptr(), buf.len()))
    return err, ret
}

FileDesc::write_io(buf<io.Buf>) i32, u64 {
    err<i32>, ret<u64> = cvt(sys_write(this.raw_fd, buf.ptr(), buf.len()))
    return err, ret
}

FileDesc::duplicate() i32, FileDesc {
    err<i32>, ret<FileDesc> = this.try_clone()
    return err, ret
}

FileDesc::close_io() {
    sys_close(this.raw_fd)
}

// Package bridge so net/sys callers avoid trait impl on FileDesc in this package.
fn file_desc_raw(fd<FileDesc>) i32 {
    return fd.raw_fd
}
