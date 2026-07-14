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
    FileDesc* desc
}

const Socket::fromfd(file_desc<FileDesc>) Socket {
    return new Socket {
        desc: new FileDesc { raw_fd: file_desc.raw_fd }
    }
}

const Socket::new(addr<net.SocketAddr>, ty<i32>) i32, Socket {
    if net.socket_addr_is_v4(addr) {
        err<i32>, sock<Socket> = new_socket_raw(AF_INET, ty)
        return err, sock
    }
    err<i32>, sock6<Socket> = new_socket_raw(AF_INET6, ty)
    return err, sock6
}

fn new_socket_raw(fam<i32>, ty<i32>) i32, Socket {
    // On platforms that support it we pass the SOCK_CLOEXEC
    // flag to atomically create the socket and set it as
    // CLOEXEC. On Linux this was added in 2.6.27.
    //TODO:
    err<i32>, sock_fd<i32> = cvt(socket(fam, ty | SOCK_CLOEXEC, 0))
    if err != Ok return err, null

    if sock_fd == 0xFFFFFFFF.(i32) {
        runtime.printf("socket new_raw invalid fd")
        os.exit(-1)
    }
    return Ok, new Socket{
        desc: new FileDesc{
            raw_fd: sock_fd
        }
    }
}

Socket::duplicate() i32, Socket {
    err<i32> , dup_desc<FileDesc> = this.desc.duplicate()
    if err != Ok return err, null

    return Ok , new Socket {
        desc: dup_desc
    }
}

Socket::recv_with_flags(buf<io.BufferCursor> , flags<i32> ) i32 {
    slice<io.Buf> = buf.as_mut()
    err<i32>, ret<i32> = cvt(
        //TODO:
        recv(
            file_desc_raw(this.desc),
            slice.ptr() ,
            slice.len(),
            flags,
        )
    )
    if err != Ok return err

    buf.advance(ret)
    return Ok
}

Socket::read(buf<io.Buf>) i32 , u64 {
    err<i32>, size<u64> = this.desc.read_io(buf)
    return err, size
}

Socket::read_buf(buf<io.BufferCursor>) i32 {
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
        recvfrom(
            file_desc_raw(this.desc),
            buf.ptr(),
            buf.len(),
            flags,
            storage,
            addrlen,
        )
    )
    if err != Ok return err

    err , skt<net.SocketAddr> = sockaddr_to_addr(storage, addrlen)
    if err != Ok return err
    
    return Ok , n , skt
}

Socket::recv_from(buf<io.Buf>) i32 , u64 , net.SocketAddr {
    err<i32> , size<u64> , addr<net.SocketAddr> = this.recv_from_with_flags(buf, 0)
    return err,size,addr
}

Socket::write(buf<io.Buf>) i32 , u64 {
    err<i32> , size<u64> = this.desc.write_io(buf)
    return err , size
}

Socket::shutdown(how<i32>) i32 {
    shut<i32> = 0
    match how {
        net.ShutdownWrite: {
            shut = SHUT_WR
        }
        net.ShutdownRead: {
            shut = SHUT_RD
        }
        net.ShutdownBoth: {
            shut = SHUT_RDWR
        }
        _: runtime.printf("shutdown type err")
    }
    //TODO:
    err<i32> =  cvt(shutdown(file_desc_raw(this.desc), shut) )
    return err
}

Socket::take_error() i32 ,i32, i32 {
    err<i32> , raw<i32>  = socket_getsockopt(this, SOL_SOCKET, SO_ERROR)
    if err != Ok return err, None, 0

    if raw == 0 { 
        return Ok , None, 0
    } else { 
        return Ok, Has, raw
    }
}

// This is used by sys_common code to abstract over Windows and Unix.
Socket::as_raw() i32 {
    return file_desc_raw(this.desc)
}

fn on_resolver_failure() {
}

fn socket_setsockopt(
    sock<Socket>,
    level<i32>,
    option_name<i32>,
    option_value<u64>,
    len<u32>,
) i32 {
    //TODO:
    err<i32> = cvt(setsockopt(
        sock.as_raw(),
        level,
        option_name,
        option_value,
        len,
    ))
    return err
}

fn socket_getsockopt(sock<Socket>, level<i32>, option_name<i32>,option_len<i32>) i32 ,u64 {
    option_value<i8*> = new option_len
    //TODO:
    err<i32> = cvt(getsockopt(
        sock.as_raw(),
        level,
        option_name,
        option_value,
        option_len,
    ))
    if err != Ok return err
    return Ok , option_value
}

// Cross-pkg: bind/accept buffers are SockaddrStorage* held as u64.
fn sockaddr_storage_new_raw() u64 {
    s<SockaddrStorage> = new SockaddrStorage{}
    return s.(u64)
}

fn sockaddr_to_addr_raw(storage_bits<u64>, len<u64>) i32, u64 {
    s<SockaddrStorage> = storage_bits.(SockaddrStorage)
    err<i32>, sa<net.SocketAddr> = sockaddr_to_addr(s, len)
    return err, sa.(u64)
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
            saddr<net.SocketAddrV4> = net.socket_addr_v4_from_ipv4_port(ipv4, U16::from_be(addr.sin_port))
            return Ok, net.socket_addr_from_v4(saddr)
        }
        AF_INET6 : {
            if len < sizeof(SockaddrIn6) {
                runtime.println("ss_family:%d sockaddrin6:%d ",len,sizeof(SockaddrIn6))
                os.exit(-1)
            }
            addr<SockaddrIn6> = storage
            saddr<In6Addr> = addr.sin6_addr
            ipv6<net.Ipv6Addr> = net.Ipv6Addr::from_u8(&saddr.s6_addr)

            sockaddr<net.SocketAddrV6> = net.socket_addr_v6_from_parts(
                ipv6,
                U16::from_be(addr.sin6_port),
                addr.sin6_flowinfo,
                addr.sin6_scope_id,
            )

            return Ok, net.socket_addr_from_v6(sockaddr)
        }
        _ : {
            return io.InvalidInputArgument
        }
    }
}

mem LookupHost {
    AddrInfo* original
    AddrInfo* cur
    u16 port_val
}

LookupHost::port_num() u16 {
    return this.port_val
}

LookupHost::next() i32,net.SocketAddr {
    loop {
        cur<AddrInfo> = this.cur
        if cur == null return None

        this.cur = cur.next
        ok<i32> , addr<net.SocketAddr> = sockaddr_to_addr(cur.ai_addr, cur.ai_addrlen)
        if ok {
            return Has,addr
        } 
        //continue
    }
}



// Package bridge for net.socket_addr.
fn lookuphost_fromstr(s<string.String>) i32, LookupHost {
    err<i32>, ret<LookupHost> = LookupHost::lookuphost_fromstr(s)
    return err, ret
}

//NOTICE: free lookuphost.original
const LookupHost::lookuphost_fromstr(s<string.String>) i32 , LookupHost {
    // Mother: s.rsplit_once(':') then parse port.
    sep = string.S(*":")
    err<i32>, host_v, port_v = string.rsplit_once(s, sep)
    if err != Ok return io.InvalidInputSocketAddress, null

    port_i64<i64> = string.tonumber_i64(port_v)
    port_num<u16> = port_i64.(u16)
    if port_num <= 0 return io.InvalidInputPortValue, null

    err,ret<LookupHost> = LookupHost::from(host_v, port_num)
    return err, ret
}

const LookupHost::from(host<string.String> , port_num<u16>) i32, LookupHost {

    hints<AddrInfo>   = new AddrInfo{}
    hints.ai_socktype = SOCK_STREAM
    res<u64> = null
    // Mother: getaddrinfo(host, null, &hints, &res)
    host_c<i8*> = string.cstr(host)
    ret<i32> = cvt_gai(getaddrinfo(host_c, null, hints, &res))
    if ret != Ok return ret, null

    return Ok , new LookupHost {
        original: res,
        cur: res,
        port_val: port_num,
    }
}

mem TcpStream {
    Socket* socket_hub
}

    
TcpStream::socket() Socket {
    return this.socket_hub
}
TcpStream::read(buf<io.Buf>) i32, u64 {
    ret<i32> , size<u64> = this.socket_hub.read(buf)
    return ret,size
}

TcpStream::read_buf(buf<io.BufferCursor>) i32 {
    return this.socket_hub.read_buf(buf)
}

TcpStream::write(buf<io.Buf>) i32, u64 {
    // Mother: min(buf.len(), wrlen_t::MAX); wrlen_t = size_t → just buf.len().
    len<u64> = buf.len()
    ok<i32> , ret<u64> = cvt(
        //TODO:
        send(this.socket_hub.as_raw(), buf.ptr(), len, MSG_NOSIGNAL)
    )
    if ok != Ok return ok, 0
    return Ok , ret
}

TcpStream::shutdown(how<i32>) i32 {
    return this.socket_hub.shutdown(how)
}

TcpStream::take_error() i32,i32,i32 {
    ok<i32>, has<i32> , ret<i32> = this.socket_hub.take_error()
    return ok,has,ret
}

mem TcpListener {
    Socket* socket_hub
}

TcpListener::socket() Socket {
    return this.socket_hub
}

mem UdpSocket {
    Socket* socket_hub
}

UdpSocket::bind(ret<i32> , addr<net.SocketAddr>) i32, UdpSocket {
    if ret != Ok return ret, null

    ret,sock<Socket> = Socket::new(addr, SOCK_DGRAM)
    if ret != Ok return ret, null

    addr_repr<SocketAddrCRepr>, len<i32> = net.socket_addr_into_inner(addr)
    addr_bits<u64> = addr_repr
    ret = cvt(bind(sock.as_raw(), addr_bits, len))
    if ret != Ok return ret, null

    return Ok , new UdpSocket{
        socket_hub: sock
    }
}

UdpSocket::socket() Socket {
    return this.socket_hub
}

UdpSocket::recv_from(buf<io.Buf>) i32, u64, net.SocketAddr {
    ret<i32> , size<u64> , addr<net.SocketAddr> = this.socket_hub.recv_from(buf)
    return ret,size,addr
}

UdpSocket::send_to(buf<io.Buf> , dst<net.SocketAddr>) i32, u64 {
    // Mother: min(buf.len(), wrlen_t::MAX); wrlen_t = size_t → just buf.len().
    len<u64> = buf.len()
    dst_repr<SocketAddrCRepr>, dstlen<i32> = net.socket_addr_into_inner(dst)
    addr_bits<u64> = dst_repr
    ok<i32> , ret<u64> = cvt(
        sendto(
            this.socket_hub.as_raw(),
            buf.ptr(),
            len,
            MSG_NOSIGNAL,
            addr_bits,
            dstlen,
        )
    )
    if ok != Ok return ok, 0
    return Ok , ret
}


mem SocketAddrCRepr {
    u64* v4_store
    u64* v6_store
}

// Mother: SocketAddrCRepr::as_ptr — pointer to the active sockaddr.
SocketAddrCRepr::as_ptr() u64 {
    v4p<u64*> = this.v4_store
    if v4p != null {
        return v4p.(u64)
    }
    v6p<u64*> = this.v6_store
    return v6p.(u64)
}

// Cross-pkg: net.socket_addr_into_inner returns SocketAddrCRepr; consumers store u64.
fn socket_addr_crepr_as_ptr_raw(bits<u64>) u64 {
    repr<SocketAddrCRepr> = bits.(SocketAddrCRepr)
    return repr.as_ptr()
}
