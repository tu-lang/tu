use std
use io
use sys
mem TcpStream {
    sys.TcpStream* inner
}


mem TcpListener {
    sys.TcpListener inner
}

TcpListener::fromrawfd(fd<sys.RawFd>)  TcpListener {
    socket<sys.Socket> = new sys.Socket{
        fd: sys.FileDesc::from_raw_fd(fd)
    }

    inner<sys.TcpListener> = new sys.TcpListener { 
        inner: socket 
    }
    
    return new TcpListener{inner: inner}
}

TcpListener::as_raw_fd()  sys.RawFd {
    return this.inner.socket().fd.as_raw_fd()
}


TcpListener::shutdown(how<i32>) i32 {
    return this.inner.shutdown(how)
}

TcpListener::take_error() i32,i32,i32 {
    ok<i32>,has<i32>,ret<i32> = this.inner.take_error()
    return ok,has,ret
}

TcpListener::asinner() sys.TcpStream {
    return this.inner
}
TcpListener::fromrawfd(fd<sys.RawFd>) TcpStream {
    
    socket<sys.Socket> = new sys.Socket {
        fd: sys.FileDesc::from_raw_fd(fd)
    }
    return new TcpStream{
        inner: new sys.TcpStream{
            inner: socket
        }
    }
}

impl io.Read for TcpStream {
    fn read(buf<io.Buffer>) i32,u64 {
        err<i32>, size<u64> = this.inner.read(buf)
        return err size
    }
}

impl io.Write for TcpStream {
    fn write(buf<io.Buffer>) i32,u64 {
        err<i32> , size<u64> = this.inner.write(buf)
        return err, size
    }
}