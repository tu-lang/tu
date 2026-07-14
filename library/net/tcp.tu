use std
use io
use sys

// TCP stream wrapper around sys.TcpStream (tustd::net::TcpStream).
mem TcpStream {
    sys.TcpStream* stream_hub // tustd: inner
}

// TCP listener wrapper around sys.TcpListener (tustd::net::TcpListener).
mem TcpListener {
    sys.TcpListener* listener_hub // tustd: inner
}

const TcpListener::fromrawfd(fd<i32>) TcpListener {
    socket<sys.Socket> = new sys.Socket{
        desc: sys.FileDesc::from_raw_fd(fd)
    }

    hub<sys.TcpListener> = new sys.TcpListener {
        socket_hub: socket
    }

    return new TcpListener{listener_hub: hub}
}

TcpListener::as_raw_fd() i32 {
    return this.listener_hub.socket().as_raw()
}

const TcpStream::fromrawfd(fd<i32>) TcpStream {
    socket<sys.Socket> = new sys.Socket {
        desc: sys.FileDesc::from_raw_fd(fd)
    }
    return new TcpStream{
        stream_hub: new sys.TcpStream{
            socket_hub: socket
        }
    }
}

TcpStream::shutdown(how<i32>) i32 {
    return this.stream_hub.shutdown(how)
}

TcpStream::take_error() i32,i32,i32 {
    ok<i32>, has<i32>, ret<i32> = this.stream_hub.take_error()
    return ok, has, ret
}

TcpStream::asinner() sys.TcpStream {
    return this.stream_hub
}

TcpStream::as_raw_fd() i32 {
    return this.stream_hub.socket().as_raw()
}

impl io.Read for TcpStream {
    fn read(buf<io.Buf>) i32,u64 {
        err<i32>, size<u64> = this.stream_hub.read(buf)
        return err, size
    }
}

impl io.Write for TcpStream {
    fn write(buf<io.Buf>) i32,u64 {
        err<i32> , size<u64> = this.stream_hub.write(buf)
        return err, size
    }
    fn flush() i32 {
        return io.Ok
    }
}
