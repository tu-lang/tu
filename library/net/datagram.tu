use sys
use io
use string

// Unix domain datagram (tustd::net::UnixDatagram).
mem UnixDatagram {
    sys.Socket* socket_hub // tustd: inner
}

UnixDatagram::recv(buf<io.Buf>) i32, u64 {
    ret<i32>, size<u64> = this.socket_hub.read(buf)
    return ret, size
}

UnixDatagram::send_to(buf<io.Buf>, path<string.String>) i32, u64 {
    ret<i32>, addr<sys.SockaddrUn>, len<u32> = sockaddr_un(path)
    if ret != Ok {
        return ret, 0
    }

    // Mother: libc::sendto(as_raw_fd(), buf, MSG_NOSIGNAL, &addr, len)
    blen<u64> = buf.len()
    flags<i32> = sys.MSG_NOSIGNAL
    addr_le<i32> = len.(i32)
    addr_bits<u64> = addr
    raw<i64> = sys.sendto(
        this.as_raw_fd(),
        buf.ptr(),
        blen,
        flags,
        addr_bits,
        addr_le,
    )
    ok<i32>, count<u64> = sys.cvt(raw)
    if ok != Ok {
        return ok, 0
    }
    return Ok, count
}

const UnixDatagram::fromrawfd(fd<i32>) UnixDatagram {
    return new UnixDatagram {
        socket_hub: sys.Socket::fromfd(sys.FileDesc::from_raw_fd(fd))
    }
}

UnixDatagram::as_raw_fd() i32 {
    return this.socket_hub.as_raw()
}

impl sys.AsRawFd for UnixDatagram {
    fn as_raw_fd() i32 {
        return this.socket_hub.as_raw()
    }
}
