AF_UNIX<i32> = 1
AF_INET<i32> = 2
AF_INET6<i32> = 10


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
    u16     sin6_family
    u16     sin6_port
    u32     sin6_flowinfo
    In6Addr sin6_addr
    u32     sin6_scope_id
}
