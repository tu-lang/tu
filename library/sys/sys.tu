SUN_PATH_LEN<i32> = 108

mem SockaddrUn {
    u16 sun_family
    i8 sun_path[SUN_PATH_LEN]
}

SockaddrUn::sun_offset() i64 {
    return this - &this.sun_path
}

mem InAddr {
    u32 s_addr
}

mem SockaddrIn {
    u16    sin_family
    u16    sin_port
    InAddr sin_addr
    u8     sin_zero[8]
}

mem In6Addr {
    u8 s6_addr[16]
}

mem SockaddrIn6 {
    u16      sin6_family
    u16      sin6_port
    u32      sin6_flowinfo
    In6Addr  sin6_addr
    u32      sin6_scope_id
}

mem SockaddrStorage {
    u16 ss_family          // 2 bytes
    u8  __ss_pad2[118]     // 118 bytes
    u16 __ss_align         // 8 bytes
}

// Layout size of SockaddrStorage (2 + 118 + 8); for cross-pkg sizeof avoidance.
SOCKADDR_STORAGE_LEN<i32> = 128


mem SockAddr {
    u16 sa_family
    i8 sa_data[14]
}

mem AddrInfo {
    i32 ai_flags
    i32 ai_family
    i32 ai_socktype
    i32 ai_protocol
    u32 ai_addrlen
    SockAddr* ai_addr

    i8* ai_canonname
    AddrInfo* next
}

// Externs for syscall/*.s — declare SHORT names so the linker symbol is
// `sys_<name>` (package + fn), matching std's `fn mmap` → `std_mmap`.
// Do NOT declare `fn sys_write` here (that becomes `sys_sys_write`).

// socket 41
fn socket(domain<i32>, ty<i32>, protocol<i32>) (i32)
// bind 49
fn bind(fd<i32>, addr<u64>, len<i32>) (i32)
// connect 42
fn connect(fd<i32>, addr<u64>, len<i32>) (i32)
// listen 50
fn listen(fd<i32>, backlog<i32>) (i32)
// accept4 288
fn accept4(fd<i32>, addr<u64>, addrlen<i32*>, flags<i32>) (i32)
// eventfd2 290
fn eventfd(initval<u32>, flags<i32>) (i32)
// sendto 44 (flags in r10)
fn send(fd<i32>, buff<u8*>, len<u64>, flags<i32>) (i64)
fn sendto(fd<i32>, buff<u8*>, len<u64>, flags<i32>, addr<u64>, addrlen<i32>) (i64)
// recvfrom 45
fn recv(fd<i32>, buff<u8*>, len<u64>, flags<i32>) (i64)
fn recvfrom(fd<i32>, buff<u8*>, len<u64>, flags<i32>, addr<u64>, addrlen<i32>) (i64)
// shutdown 48
fn shutdown(fd<i32>, how<i32>) (i32)
// setsockopt / getsockopt 54 / 55
fn setsockopt(fd<i32>, level<i32>, optname<i32>, optval<u64>, optlen<u32>) (i32)
fn getsockopt(fd<i32>, level<i32>, optname<i32>, optval<u64>, optlen<i32>) (i32)
// getaddrinfo is libc (not a Linux syscall). Asm stub returns EAI_FAIL until a resolver exists.
fn getaddrinfo(node<i8*>, service<u64>, hints<AddrInfo>, res<u64*>) (i32)
// fcntl 72
fn fcntl(fd<i32>, cmd<i32>, arg<i32>) (i32)
// read 0 / write 1 / close 3
fn read(fd<i32>, buff<u8*>, len<u64>) (i64)
fn write(fd<i32>, buff<u8*>, len<u64>) (i64)
fn close(fd<i32>)
// socketpair 53
fn socketpair(domain<i32>, ty<i32>, protocol<i32>, sv<i32*>) (i32)
// epoll_* — used by netio; keep under sys so symbols are sys_epoll_*
fn epoll_create1(flags<i32>) (i32)
fn epoll_ctl(epfd<i32>, op<i32>, fd<i32>, event<u64>) (i32)
fn epoll_wait(epfd<i32>, events<u64>, maxevents<i32>, timeout_ms<i32>) (i32)
// path helpers used by asyncio.fs
fn readlink(path<i8*>, buf<i8*>, bufsiz<u64>) (i64)
fn rename(oldpath<i8*>, newpath<i8*>) (i32)
fn link(oldpath<i8*>, newpath<i8*>) (i32)
fn symlink(target<i8*>, linkpath<i8*>) (i32)
