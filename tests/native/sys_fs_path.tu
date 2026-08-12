// Formal tests for library/sys path syscalls and socket ABI used by asyncio/netio:
// mkdir / openat / write / close / unlink / rmdir, kill, cvt,
// getsockopt(optlen i32*), recvfrom(addrlen i32*).
// UdpSocket::send_to sockaddr as_ptr fix covered by tests/asyncio/int_udp_recv.tu.

use fmt
use os
use std
use sys
use string
use io
use runtime

// No-body sys.mkdir from a mem method: IntExpr must still unbox via registercall argCast.
mem FsBox {
    i8* dirp
}
FsBox::mkdir0755() i32 {
    return sys.mkdir(this.dirp, 493)
}

fn main(){
    fmt.println("test sys fs path")
    dir_s<string.String> = string.S(*"/tmp/tu_lib_formal_sys_dir3")
    file_s<string.String> = string.S(*"/tmp/tu_lib_formal_sys_dir3/f.txt")
    dirp<i8*> = string.cstr(dir_s)
    filep<i8*> = string.cstr(file_s)
    sys.unlink(filep)
    sys.rmdir(dirp)
    mk<i32> = sys.mkdir(dirp, 493)
    if mk != 0 {
        os.die("mkdir literal 493 failed")
    }
    flags<i64> = std.O_CREAT
    flags = flags + std.O_RDWR
    flags = flags + std.O_TRUNC
    mode<i64> = 420
    fd<i32> = sys.openat(std.AT_FDCWD, filep, flags, mode)
    if fd < 0 {
        os.die("openat failed")
    }
    msg_s<string.String> = string.S(*"hi-sys")
    wbuf<u8*> = string.cstr(msg_s)
    wrote_n<i64> = sys.write(fd, wbuf, 6)
    if wrote_n != 6 {
        os.die("write literal 6 failed")
    }
    sys.close(fd)
    sys.unlink(filep)
    sys.rmdir(dirp)

    // registercall + argCast: type assert / typed local / mem method, not only IntExpr.
    // Untyped `400+93` still boxes (same stackcall argCast gap); use typed add.
    extra<i64> = 400
    extra = extra + 93
    mk = sys.mkdir(dirp, extra)
    if mk != 0 {
        os.die("mkdir typed local 400+93 failed")
    }
    sys.rmdir(dirp)
    mk = sys.mkdir(dirp, 493.(i64))
    if mk != 0 {
        os.die("mkdir typeassert 493.(i64) failed")
    }
    sys.rmdir(dirp)
    box<FsBox> = new FsBox
    box.dirp = dirp
    mk = box.mkdir0755()
    if mk != 0 {
        os.die("mkdir from mem method literal failed")
    }
    fd = sys.openat(std.AT_FDCWD, filep, flags, mode)
    if fd < 0 {
        os.die("openat after mem mkdir failed")
    }
    nlen<u64> = 3
    nlen = nlen + 3
    wrote_n = sys.write(fd, wbuf, nlen)
    if wrote_n != 6 {
        os.die("write typed local 3+3 failed")
    }
    sys.close(fd)
    fd = sys.openat(std.AT_FDCWD, filep, flags, mode)
    if fd < 0 {
        os.die("openat before typeassert write failed")
    }
    wrote_n = sys.write(fd, wbuf, 6.(u64))
    if wrote_n != 6 {
        os.die("write typeassert 6.(u64) failed")
    }
    sys.close(fd)
    sys.unlink(filep)
    sys.rmdir(dirp)

    // kill(pid, 0) existence probe.
    k0<i32> = sys.kill(1, 0)
    if k0 > 0 {
        os.dief("kill(1,0) unexpected %d", k0)
    }

    // cvt(success): only need err — omit unused u64 return (do not use `_`).
    z<i32> = 0
    cerr<i32> = sys.cvt(z)
    if cerr != 1 {
        os.dief("cvt(0) err %d", cerr)
    }

    // getsockopt SOL_SOCKET/SO_ERROR with socklen_t* optlen.
    fam<i32> = 2
    sty<i32> = 1
    proto<i32> = 0
    sfd<i32> = sys.socket(fam, sty, proto)
    if sfd < 0 {
        os.dief("socket %d", sfd)
    }
    optval<i32> = 0
    optlen<i32> = 4
    vp<i32*> = &optval
    oval_bits<u64> = vp.(u64)
    level<i32> = 1
    optname<i32> = 4
    gs<i32> = sys.getsockopt(sfd, level, optname, oval_bits, &optlen)
    if gs != 0 {
        os.dief("getsockopt %d", gs)
    }
    if optlen != 4 {
        os.dief("getsockopt optlen %d", optlen)
    }
    if optval != 0 {
        os.dief("getsockopt SO_ERROR %d", optval)
    }
    sys.close(sfd)

    // recvfrom with socklen_t* addrlen: nonblocking empty UDP → -EAGAIN, no crash.
    dgram_ty<i32> = 2
    ufd<i32> = sys.socket(fam, dgram_ty, proto)
    if ufd < 0 {
        os.dief("udp socket %d", ufd)
    }
    fcntl_cmd<i32> = 4
    onb<i32> = 2048
    sys.fcntl(ufd, fcntl_cmd, onb)
    b<io.Buf> = io.NewBuf(64)
    stor<u64> = runtime.malloc(128, 0.(i8), 1.(i8))
    addrlen<i32> = 128
    fl<i32> = 0
    nlen<u64> = 64
    rn<i64> = sys.recvfrom(ufd, b.ptr(), nlen, fl, stor, &addrlen)
    if rn >= 0 {
        os.dief("recvfrom unexpected ok %d", rn)
    }
    if addrlen != 128 {
        os.dief("recvfrom addrlen clobber %d", addrlen)
    }
    sys.close(ufd)

    // sockaddr_to_addr must accept kernel wire len (16), not Tu sizeof(SockaddrIn)=24.
    stor2_bits<u64> = sys.sockaddr_storage_new_raw()
    // Pack AF_INET sockaddr_in: family=2, port=34567 BE, 127.0.0.1
    wire<u8*> = runtime.malloc(16, 0.(i8), 1.(i8))
    i<i32> = 0
    while i < 16 {
        wire[i] = 0
        i += 1
    }
    wire[0] = 2
    wire[1] = 0
    wire[2] = 0x87
    wire[3] = 0x07
    wire[4] = 127
    wire[5] = 0
    wire[6] = 0
    wire[7] = 1
    std.memcpy(stor2_bits, wire, 16)
    wire_len<u64> = 16
    sa_err<i32>, abits<u64> = sys.sockaddr_to_addr_raw(stor2_bits, wire_len)
    if sa_err != io.Ok {
        os.dief("sockaddr_to_addr_raw wire16 %d", sa_err)
    }
    if abits == 0 {
        os.die("sockaddr_to_addr_raw null addr")
    }

    // Loopback TCP: bind/listen/connect/accept/send/recv.
    lfd<i32> = sys.socket(2, 1, 0)
    if lfd < 0 {
        os.dief("tcp listen socket %d", lfd)
    }
    one<i32> = 1
    onep<i32*> = &one
    one_bits<u64> = onep.(u64)
    olen<i32> = 4
    sys.setsockopt(lfd, 1, 2, one_bits, olen)
    sa_bits<u64> = runtime.malloc(16, 0.(i8), 1.(i8))
    sap<u8*> = sa_bits
    i = 0
    while i < 16 {
        sap[i] = 0
        i += 1
    }
    sap[0] = 2
    sap[1] = 0
    // port 0 — kernel assigns
    sap[4] = 127
    sap[5] = 0
    sap[6] = 0
    sap[7] = 1
    br<i32> = sys.bind(lfd, sa_bits, 16)
    if br != 0 {
        os.dief("tcp bind %d", br)
    }
    lr<i32> = sys.listen(lfd, 1)
    if lr != 0 {
        os.dief("tcp listen %d", lr)
    }
    // Read assigned port via getsockname is not wrapped; use fixed high port.
    // Re-bind on an explicit port for the client connect.
    sys.close(lfd)
    lfd = sys.socket(2, 1, 0)
    if lfd < 0 {
        os.dief("tcp listen socket2 %d", lfd)
    }
    sys.setsockopt(lfd, 1, 2, one_bits, olen)
    // htons(34568) = 0x8708
    sap[2] = 0x87
    sap[3] = 0x08
    br = sys.bind(lfd, sa_bits, 16)
    if br != 0 {
        os.dief("tcp bind2 %d", br)
    }
    lr = sys.listen(lfd, 1)
    if lr != 0 {
        os.dief("tcp listen2 %d", lr)
    }
    cfd<i32> = sys.socket(2, 1, 0)
    if cfd < 0 {
        os.dief("tcp client socket %d", cfd)
    }
    cr<i32> = sys.connect(cfd, sa_bits, 16)
    if cr != 0 && cr != -115 && cr != -11 {
        os.dief("tcp connect %d", cr)
    }
    alen<i32> = 16
    afd<i32> = sys.accept4(lfd, sa_bits, &alen, 0)
    if afd < 0 {
        os.dief("tcp accept4 %d", afd)
    }
    msg2_s<string.String> = string.S(*"ping")
    w2<u8*> = string.cstr(msg2_s)
    wn<i64> = sys.send(cfd, w2, 4, 0)
    if wn != 4 {
        os.dief("tcp send %d", wn)
    }
    rbuf_bits<u64> = runtime.malloc(8, 0.(i8), 1.(i8))
    rn2<i64> = sys.recv(afd, rbuf_bits, 8, 0)
    if rn2 != 4 {
        os.dief("tcp recv %d", rn2)
    }
    sys.close(afd)
    sys.close(cfd)
    sys.close(lfd)

    fmt.println("test sys fs path success")
}
