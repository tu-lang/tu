use std
use io
use sys

mem UdpSocket {
    sys.UdpSocket* inner
}

  
UdpSocket::recv_from(buf<io.Buffer>) i32,u64,SocketAddr {
    err<i32> , size<u64> , addr<SocketAddr> = this.inner.recv_from(buf)
    return err,size,addr
}

UdpSocket::send_to(buf<io.Buffer> , addr<SocketAddr>) i32,u64 {
    err<i32> , size<u64> = this.inner.send_to(buf, addr)
    return err,size
}
UdpSocket::fromrawfd(fd<sys.RawFd>)  UdpSocket {
    socket<sys.Socket> = new sys.Socket {
        fd: sys.FileDesc::from_raw_fd(fd)
    }
    return new UdpSocket{
        inner: new sys.UdpSocket { 
            inner: socket 
        }
    }
}
