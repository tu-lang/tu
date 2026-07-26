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

fn main(){
    fmt.println("test sys fs path")
    dir_s<string.String> = string.S(*"/tmp/tu_lib_formal_sys_dir3")
    file_s<string.String> = string.S(*"/tmp/tu_lib_formal_sys_dir3/f.txt")
    dirp<i8*> = string.cstr(dir_s)
    filep<i8*> = string.cstr(file_s)
    sys.unlink(filep)
    sys.rmdir(dirp)
    mk<i32> = sys.mkdir(dirp, 493)
    flags<i64> = std.O_CREAT
    flags = flags + std.O_RDWR
    flags = flags + std.O_TRUNC
    mode<i64> = 420
    fd<i32> = sys.openat(std.AT_FDCWD, filep, flags, mode)
    if fd < 0 {
        os.dief("openat %d", fd)
    }
    msg_s<string.String> = string.S(*"hi-sys")
    wbuf<u8*> = string.cstr(msg_s)
    wrote_n<i64> = sys.write(fd, wbuf, 6)
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
    stor<u64> = std.malloc(128)
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
    wire<u8*> = std.malloc(16)
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

    fmt.println("test sys fs path success")
}
