use sys
use io

mem UnixDatagram {
    sys.Socket* inner
}

UnixDatagram::recv(buf<u8*>) i32,u64 {
    ret<i32>,size<i32> = this.inner.read(buf)
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

const UnixDatagram::fromrawfd(fd<sys.RawFd>)  UnixDatagram {
    return new UnixDatagram {
        inner: sys.Socket::fromfd(sys.FileDesc::from_raw_fd(fd))
    }
}

impl sys.AsRawFd for UnixDatagram {
    
    fn as_raw_fd()  sys.RawFd {
        return this.inner.fd.as_raw_fd()
    }
}

