use std
use io
use sys

// UDP socket wrapper around sys.UdpSocket.
mem UdpSocket {
    sys.UdpSocket* socket_hub
}

UdpSocket::recv_from(buf<io.Buf>) i32,u64,net.SocketAddr {
    err<i32> , size<u64> , addr<net.SocketAddr> = this.socket_hub.recv_from(buf)
    return err,size,addr
}

UdpSocket::send_to(buf<io.Buf> , addr<net.SocketAddr>) i32,u64 {
    err<i32> , size<u64> = this.socket_hub.send_to(buf, addr)
    return err,size
}

const UdpSocket::fromrawfd(fd<i32>)  UdpSocket {
    socket<sys.Socket> = new sys.Socket {
        desc: sys.FileDesc::from_raw_fd(fd)
    }
    return new UdpSocket{
        socket_hub: new sys.UdpSocket {
            socket_hub: socket
        }
    }
}

UdpSocket::as_raw_fd() i32 {
    return this.socket_hub.socket().as_raw()
}

impl sys.AsRawFd for UdpSocket {
    fn as_raw_fd() i32 {
        return this.socket_hub.socket().as_raw()
    }
}
