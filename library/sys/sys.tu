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


//TODO:
//sys_sendto 44
//@param fd i32
//@param buff u8*
//@param len i64
//TODO:@param flags u8    rcx to r10
//@param addr u8*
//@param addr_le i32
fn send_to(fd<i32>,buff<u8*> len<i64>,flags<i64>, addr<SockaddrUn> , addr_le<i32>) 