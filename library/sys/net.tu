use io
use net

fn cvt_gai(err<i32>) i32 {
    if err == 0 {
        return Ok 
    }

    on_resolver_failure()

    return decode_error_code(err)
}

mem Socket {
    FileDesc* fd
}

const Socket::fromfd(file_desc<FileDesc>) FileDesc {
    return new FileDesc{fd: file_desc}
}

Socket::new(addr<net.SocketAddr>, ty<i32>) i32, Socket {
    match addr.v4() {
        true : return Socket::new_raw(AF_INET, ty)
        false: return Socket::new_raw(AF_INET6, ty)
    }
}

const Socket::new_raw(fam<i32> , ty<i32>) i32, Socket {
    // On platforms that support it we pass the SOCK_CLOEXEC
    // flag to atomically create the socket and set it as
    // CLOEXEC. On Linux this was added in 2.6.27.
    //TODO:
    err<i32>,fd<i32> = cvt(sys_socket(fam, ty | SOCK_CLOEXEC, 0))
    if err != Ok return err,fd

    if fd == runtime.U32_MAX {
        runtime.printf("socket new_raw invalid fd")
        os.exit(-1)
    }
    return Ok, new Socket{
        fd: new FileDesc{
            fd: fd
        }
    }
}

Socket::duplicate() i32, Socket {
    err<i32> , fd<FileDesc> = this.fd.duplicate()
    if err != Ok return err

    return Ok , new Socket {
        fd: fd
    }
}

Socket::recv_with_flags(buf<io.ReadBufCursor> , flags<i32> ) i32 {
    err<i32>, ret<i32> = cvt(
        //TODO:
        sys_recv(
            this.fd.as_raw_fd(),
            buf.ptr() ,
            buf.capacity(),
            flags,
        )
    )
    if err != Ok return err

    buf.advance(ret)
    return Ok
}

Socket::read(buf<io.Buf>) i32 , u64 {
    buf<io.ReadBuf> = io.ReadBuf::from(buf)
    err<i32> = this.recv_with_flags(buf.unfilled(), 0)
    if err != Ok return err

    return Ok, buf.len()
}

Socket::read_buf(buf<io.ReadBufCursor>) i32 {
    return this.recv_with_flags(buf, 0)
}

Socket::recv_from_with_flags(
    buf<io.Buf>,
    flags<i32>,
) i32,u64,net.SocketAddr {

    storage<SockaddrStorage> = new SockaddrStorage{}
    addrlen<i32> = sizeof(SockaddrStorage)

    err<i32> , n<i64> = cvt(
        //TODO:
        sys_recvfrom(
            this.fd.as_raw_fd(),
            buf.ptr()
            buf.len(),
            flags,
            storage,
            addrlen,
        )
    )
    if err != Ok return err

    err , skt<SocketAddr> = sockaddr_to_addr(storage, addrlen)
    if err != Ok return err
    
    return Ok , n , skt
}

Socket::recv_from(buf<io.Buf>) i32 , u64 , net.SocketAddr {
    err<i32> , size<u64> , addr<net.SocketAddr> = this.recv_from_with_flags(buf, 0)
    return err,size,addr
}

Socket::write(buf<io.Buf>) i32 , u64 {
    err<i32> , size<u64> = this.fd.write(buf)
    return err , size
}

Socket::shutdown(how<i32>) i32 {
    let how<i32> = 0
    match how {
        net.ShutdownWrite: how =  SHUT_WR,
        net.ShutdownRead:  how =  SHUT_RD,
        net.ShutdownBoth:  how = SHUT_RDWR,
        _: runtime.printf("shutdown type err")
    };
    //TODO:
    err<i32> =  cvt(sys_shutdown(this.fd.as_raw_fd(), how) )
    return err
}

Socket::take_error() i32 ,i32, i32 {
    err<i32> , raw<i32>  = getsockopt(this, SOL_SOCKET, SO_ERROR)
    if err != Ok return err

    if raw == 0 { 
        return Ok , None
    } else { 
        return Ok, Has,raw
    }
}

// This is used by sys_common code to abstract over Windows and Unix.
Socket::as_raw() i32 {
    return this.fd.as_raw_fd()
}

fn on_resolver_failure() {
}

fn setsockopt(
    sock<Socket>,
    level<i32>,
    option_name<i32>,
    option_value<u64>,
    len<u32>,
) i32 {
    //TODO:
    err<i32> = cvt(sys_setsockopt(
        sock.as_raw(),
        level,
        option_name,
        option_value,
        len,
    ));
    return err
}

fn getsockopt(sock<Socket>, level<i32>, option_name<i32>,option_len<i32>) i32 ,u64 {
    option_value<i8*> = new option_len
    //TODO:
    err<i32> = cvt(sys_getsockopt(
        sock.as_raw(),
        level,
        option_name,
        option_value,
        option_len,
    ))
    if err != Ok return err
    return Ok , option_value
}

fn sockaddr_to_addr(storage<SockaddrStorage>, len<u64>) i32,net.SocketAddr {
    match storage.ss_family {
        AF_INET : {
            if len < sizeof(SockaddrIn) {
                runtime.println("ss_family:%d sockaddrin:%d ",len,sizeof(SockaddrIn))
                os.exit(-1)
            }
            addr<SockaddrIn> = storage
            sinaddr<InAddr> = addr.sin_addr
            ipv4<net.Ipv4Addr> = net.Ipv4Addr::from(&sinaddr.s_addr)
            saddr<SocketAddrV4> = net.SocketAddrV4::new(ipv4, u16::from_be(addr.sin_port))
            return Ok , saddr
        }
        AF_INET6 : {
            if len < sizeof(SockaddrIn6) {
                runtime.println("ss_family:%d sockaddrin6:%d ",len,sizeof(SockaddrIn6))
                os.exit(-1)
            }
            addr<SockaddrIn6> = storage
            saddr<In6Addr> = addr.sin6_addr
            ipv6<Ipv6Addr> = net.Ipv6Addr::from_u8(&saddr.s6_addr);

            sockaddr<SocketAddrV6> = net.SocketAddrV6::new(
                ipv6,
                U16::from_be(addr.sin6_port),
                addr.sin6_flowinfo,
                addr.sin6_scope_id,
            )

            return Ok , sockaddr
        }
        _ => return io.InvalidInputArgument
    }
}

mem LookupHost {
    AddrInfo* original
    AddrInfo* cur
    u16 port
}

LookupHost::port() u16 {
    return this.port
}

LookupHost::next() i32,net.SockAddr {
    loop {
        cur<AddrInfo> = this.cur
        if cur == null return None

        this.cur = cur.ai_next
        ok<i32> , addr<net.SockAddr> =  sockaddr_to_addr(cur.ai_addr, cur.ai_addrlen ) {
        if ok {
            return Has,addr
        } 
        //continue
    }
}



//NOTICE: free lookuphost.original
const LookupHost::lookuphost_fromstr(s<string.String>) i32 , LookupHost {
    err<i32> , host<string.Sring,port_str<string.String> = s.rSplitOnce(string.S(*":"))
    if err != Ok return io.InvalidInputSocketAddress

    port<u16> = port_str.tonumber()
    if port <= 0 return io.InvalidInputPortValue

    err,ret<LookupHost> = LookupHost::from(host,port)
    return err, ret
}

const LookupHost::from(host<string.String> , port<u16>) i32, LookupHost {

    hints<AddrInfo>   = new AddrInfo{}
    hints.ai_socktype = SOCK_STREAM
    res<u64> = null
    //TODO:
    ret<i32> = cvt_gai(sys_getaddrinfo(host.str(), null, hints, &res))
    if ret != Ok return ret

    return Ok , new LookupHost {
        original: res,
        cur: res,
        port: port,
    }
}

mem TcpStream {
    Socket* inner
}

    
TcpStream::socket() Socket {
    return this.inner
}
TcpStream::read(buf<io.Buf>) i32, u64 {
    ret<i32> , size<u64> = this.inner.read(buf)
    return ret,size
}

TcpStream::read_buf(buf<io.BufferCursor>) i32 {
    return this.inner.read_buf(buf)
}

TcpStream::write(buf<io.Buf>) i32, u64 {
    len<i32> = runtime.U16_MAX
    if buf.len() < len {
        len = buf.len()
    }
    ok<i32> , ret<i32> = cvt(
        //TODO:
        sys_send(this.inner.as_raw(), buf.ptr(), len, MSG_NOSIGNAL)
    )
    if ok != Ok return ok
    return Ok , ret
}

TcpStream::shutdown(how<i32>) i32 {
    return this.inner.shutdown(how)
}

TcpStream::take_error() i32,i32,i32 {
    ok<i32>, has<i32> , ret<i32> = this.inner.take_error()
    return ok,has,ret
}

mem TcpListener {
    Socket* inner
}

TcpListener::socket() Socket {
    return this.inner
}

mem UdpSocket {
    Socket* inner
}

UdpSocket::bind(ret<i32> , addr<net.SocketAddr>) i32, UdpSocket {
    if ret != Ok return ret

    ret,sock<Socket> = Socket::new(addr, SOCK_DGRAM)
    if ret != Ok return ret

    addr<u64>, len<i32> = addr.into_inner()
    //TODO:
    ret = cvt(sys_bind(sock.as_raw(), addr, len))
    if ret != Ok return ret

    return Ok , new UdpSocket{
        inner: sock
    }
}

UdpSocket::socket() Socket {
    return this.inner
}

UdpSocket::recv_from(buf<io.Buf>) i32, u64, net.SocketAddr {
    ret<i32> , size<u64> , addr<net.SocketAddr> = this.inner.recv_from(buf)
    return ret,size,addr
}

UdpSocket::send_to(buf<io.Buf> , dst<net.SocketAddr>) i32, u64 {
    len<i32> = runtime.U16_MAX
    if buf.len() < len {
        len = buf.len()
    }
    dst, dstlen<i32> = dst.into_inner()
    ok<i32> , ret<i32> = cvt(
        //TODO:
        sys_sendto(
            this.inner.as_raw(),
            buf.ptr(),
            len,
            MSG_NOSIGNAL,
            dst,
            dstlen,
        )
    )
    if ok != Ok return ok
    return Ok , ret
}


mem SocketAddrCRepr {
    u64* v4 
    u64* v6
}