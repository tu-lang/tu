use io

// Raw Unix-like file descriptors.
api AsRawFd {
    fn as_raw_fd() i32
}

mem FileDesc {
    i32 fd
}

READ_LIMIT<u64> = 18446744073709551615
UIO_MAXIOV<i32> = 1024
F_DUPFD_CLOEXEC<i32> = 1030;


fn max_iov() u64 {
    return UIO_MAXIOV
}

FileDesc::try_clone() i32 ,FileDesc {
    raw_fd<i32> = this.fd
    cmd<i32> = F_DUPFD_CLOEXEC
    //TODO
    err<i32>, fd<i32> = cvt(sys_fcntl(raw_fd, cmd, 3))
    if err != Ok return err

    return Ok, new FileDesc {
        fd: fd
    }
}

FileDesc::from_raw_fd(fd<i32> ) FileDesc {
    if fd == runtime.U32_MAX {
        runtime.printf("fd is u32 max\n")
        os.die(1)
    }
    // SAFETY: we just asserted that the value is in the valid range and isn't `-1` (the only value bigger than `0xFF_FF_FF_FE` unsigned)
    return new FileDesc {
        fd: fd
    }
}

FileDesc::read(buf<io.Buffer>) i32,u64 {
    err<i32>,  ret<i64> = cvt(
        //TODO:
        sys_read(
            this.as_raw_fd(),
            buf.ptr(),
            buf.len()
        )
    )
    return err,ret
}

FileDesc::write(buf<io.Buffer>) i32, u64 {
    err<i32> , ret<u64> = cvt(
        //TODO
        sys_write(
            this.as_raw_fd(),
            buf.ptr(),
            buf.len()
        )
    )
    return err, ret
}

FileDesc::duplicate() i32, FileDesc {
    err<i32> , ret<FileDesc> = this.try_clone()
    return err,ret
}

FileDesc::as_raw_fd() i32 {
    return this.fd
}

FileDesc::close() {
    //TODO:
    sys_close(this.fd)
}
