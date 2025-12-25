use sys

mem UnixListener {
    sys.Socket* inner
}

impl sys.AsRawFd for UnixListener {
    
    fn as_raw_fd() i32 {
        return this.inner.fd.as_raw_fd()
    }
}

UnixListener::fromrawfd(fd<i32>)  UnixListener {
    return new UnixListener {
        inner: new sys.Socket {
            fd: sys.FileDesc::from_raw_fd(fd)
        }
    }
}
