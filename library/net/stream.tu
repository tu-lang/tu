use io
use sys

// Unix domain stream backed by sys.Socket.
mem UnixStream {
    sys.Socket* socket_hub
}

UnixStream::try_clone() i32, UnixStream {
    err<i32>, sock<sys.Socket> = this.socket_hub.duplicate()
    if err != io.Ok {
        return err, null
    }
    return io.Ok, new UnixStream { socket_hub: sock }
}

UnixStream::take_error() i32, i32 , i32 {
    ok<i32>,has<i32>,err<i32> = this.socket_hub.take_error()
    return ok,has,err
}

UnixStream::shutdown(how<i32>) i32 {
    return this.socket_hub.shutdown(how)
}

UnixStream::fromrawfd(fd<i32>) UnixStream {
    return new UnixStream{
        socket_hub: new sys.Socket{
            desc: sys.FileDesc::from_raw_fd(fd)
        }
    }
}

UnixStream::as_raw_fd() i32 {
    return this.socket_hub.as_raw()
}

impl io.Read for UnixStream {
    fn read(buf<io.Buf>) i32,u64 {
        err<i32>,size<u64> = this.socket_hub.read(buf)
        return err,size
    }
}

impl io.Write for UnixStream {
    fn write(buf<io.Buf>) i32,u64 {
        err<i32>, size<u64> = this.socket_hub.write(buf)
        return err,size
    }
    fn flush() i32 {
        return io.Ok
    }
}
