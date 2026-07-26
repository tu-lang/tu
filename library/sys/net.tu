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
    ce<i32> = SOCK_CLOEXEC
    full_ty<i32> = ty | ce
    proto<i32> = 0
    err<i32>, sock_fd<i32> = cvt(socket(fam, full_ty, proto))
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
        recvfrom(
            file_desc_raw(this.desc),
            buf.ptr(),
            buf.len(),
            flags,
            storage,
            &addrlen,
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
    // Mother: getsockopt SOL_SOCKET/SO_ERROR → Option<i32>.
    optlen<i32> = 4
    err<i32> , raw<i32>  = socket_getsockopt_i32(this, SOL_SOCKET, SO_ERROR, optlen)
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
    err<i32> = cvt(setsockopt(
        sock.as_raw(),
        level,
        option_name,
        option_value,
        len,
    ))
    return err
}

// Mother getsockopt<T>: &mut optval + &mut optlen. Returns (err, value as i32).
fn socket_getsockopt_i32(sock<Socket>, level<i32>, option_name<i32>, optlen_in<i32>) i32 ,i32 {
    optval<i32> = 0
    optlen<i32> = optlen_in
    // Same pattern as netio set_reuseaddr_fd: &val via i32* then .(u64).
    vp<i32*> = &optval
    oval_bits<u64> = vp.(u64)
    err<i32> = cvt(getsockopt(
        sock.as_raw(),
        level,
        option_name,
        oval_bits,
        &optlen,
    ))
    if err != Ok return err, 0
    return Ok , optval
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
    // Kernel wire sizes (Tu sizeof(SockaddrIn/In6) pads nested mem past these).
    min_v4<u64> = 16
    min_v6<u64> = 28
    match storage.ss_family {
        AF_INET : {
            if len < min_v4 {
                return io.InvalidInputArgument, null
            }
            addr<SockaddrIn> = storage
            sinaddr<InAddr> = addr.sin_addr
            ipv4<net.Ipv4Addr> = net.Ipv4Addr::from(&sinaddr.s_addr)
            saddr<net.SocketAddrV4> = net.socket_addr_v4_from_ipv4_port(ipv4, U16::from_be(addr.sin_port))
            return Ok, net.socket_addr_from_v4(saddr)
        }
        AF_INET6 : {
            if len < min_v6 {
                return io.InvalidInputArgument, null
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
            return io.InvalidInputArgument, null
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

fn tcp_stream_as_raw_fd(s<TcpStream>) i32 {
    sock<Socket> = s.socket_hub
    return sock.as_raw()
}

fn tcp_stream_as_raw_fd_bits(bits<u64>) i32 {
    s<TcpStream> = bits.(TcpStream)
    return tcp_stream_as_raw_fd(s)
}

fn tcp_stream_shutdown_bits(bits<u64>, how<i32>) i32 {
    s<TcpStream> = bits.(TcpStream)
    return s.shutdown(how)
}

fn tcp_stream_take_error_bits(bits<u64>) i32,i32,i32 {
    s<TcpStream> = bits.(TcpStream)
    ok<i32>, has<i32>, ret<i32> = s.take_error()
    return ok, has, ret
}

fn tcp_stream_read_bits(bits<u64>, buf<io.Buf>) i32, u64 {
    s<TcpStream> = bits.(TcpStream)
    err<i32>, n<u64> = s.read(buf)
    return err, n
}

fn tcp_stream_write_bits(bits<u64>, buf<io.Buf>) i32, u64 {
    s<TcpStream> = bits.(TcpStream)
    err<i32>, n<u64> = s.write(buf)
    return err, n
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
    // Localize socket_hub — chaining this.socket_hub.method() returns garbage / segfaults.
    sock<Socket> = this.socket_hub
    return sock.shutdown(how)
}

TcpStream::take_error() i32,i32,i32 {
    sock<Socket> = this.socket_hub
    ok<i32>, has<i32>, ret<i32> = sock.take_error()
    return ok, has, ret
}

mem TcpListener {
    Socket* socket_hub
}

// Cross-pkg bridge: net.TcpListener::as_raw_fd must not chain
// listener_hub.socket().as_raw() (codegen returns garbage across packages).
fn tcp_listener_as_raw_fd(l<TcpListener>) i32 {
    sock<Socket> = l.socket_hub
    return sock.as_raw()
}

fn tcp_listener_from_fd(fd_val<i32>) u64 {
    sock<Socket> = new Socket{
        desc: FileDesc::from_raw_fd(fd_val)
    }
    hub<TcpListener> = new TcpListener {
        socket_hub: sock
    }
    return hub.(u64)
}

fn tcp_stream_from_fd(fd_val<i32>) u64 {
    sock<Socket> = new Socket{
        desc: FileDesc::from_raw_fd(fd_val)
    }
    hub<TcpStream> = new TcpStream {
        socket_hub: sock
    }
    return hub.(u64)
}

fn tcp_listener_as_raw_fd_bits(bits<u64>) i32 {
    l<TcpListener> = bits.(TcpListener)
    return tcp_listener_as_raw_fd(l)
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
    // Mother: sockaddr pointer is crepr.as_ptr(), not the wrapper object itself.
    addr_bits<u64> = addr_repr.as_ptr()
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
    // sendto requires sockaddr*; SocketAddrCRepr is a v4/v6 store wrapper.
    addr_bits<u64> = dst_repr.as_ptr()
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
