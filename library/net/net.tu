use sys

/// Possible values which can be passed to the [`TcpStream::shutdown`] method.
ShutdownRead<i32> = 1
ShutdownWrite<i32> = 2
ShutdownBoth<i32> = 3

impl sys.AsRawFd for TcpStream {
    fn as_raw_fd() sys.RawFd {
        return this.asinner().socket().as_raw()
    }
}

impl sys.AsRawFd for TcpListener {
    
    fn as_raw_fd() -> sys.RawFd {
        return this.inner.socket().as_raw()
    }
}

impl sys.AsRawFd for UdpSocket {
    fn as_raw_fd() -> sys.RawFd {
        return this.inner.socket().as_raw()
    }
}
