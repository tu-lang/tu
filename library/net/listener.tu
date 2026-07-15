use sys

// Unix domain listener backed by sys.Socket.
mem UnixListener {
    sys.Socket* socket_hub
}

UnixListener::as_raw_fd() i32 {
    return this.socket_hub.as_raw()
}

impl sys.AsRawFd for UnixListener {
    fn as_raw_fd() i32 {
        return this.socket_hub.as_raw()
    }
}

UnixListener::fromrawfd(fd<i32>)  UnixListener {
    return new UnixListener {
        socket_hub: new sys.Socket {
            desc: sys.FileDesc::from_raw_fd(fd)
        }
    }
}
