use sys
use io

// Unix domain datagram socket backed by sys.Socket.
mem UnixDatagram {
    sys.Socket* socket_hub
}

UnixDatagram::recv(buf<u8*>) i32,u64 {
    ret<i32>,size<i32> = this.socket_hub.read(buf)
    return ret,size
}

UnixDatagram::send_to(buf<string.String>, path<string.String>) i32,u64 {
    ret<i32>,addr<sys.SockaddrUn>, len<i32> = sockaddr_un(path)
    if ret != Ok {
        return ret
    }

    ret<i32>,count<i64> = sys.cvt(sendto(
        this.as_raw_fd(),
        buf.str(),
        buf.len(),
        sys.MSG_NOSIGNAL,
        addr,
        len,
    ))
    if ret != Ok {
        return ret
    }
    return Ok,count
}

const UnixDatagram::fromrawfd(fd<i32>)  UnixDatagram {
    return new UnixDatagram {
        socket_hub: sys.Socket::fromfd(sys.FileDesc::from_raw_fd(fd))
    }
}

UnixDatagram::as_raw_fd() i32 {
    return this.socket_hub.as_raw()
}
