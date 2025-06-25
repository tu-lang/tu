AF_INET<i32>  = 2
AF_INET6<i32> = 10

SOCK_STREAM<i32> = 1
SOCK_DGRAM<i32>  = 2
SOCK_RAW<i32>    = 3

SOCK_CLOEXEC<i32> = 0x80000

api SocketAddr {
	fn isv4() (i32)
}

mem Ipv4Addr {
    u8 octets[4]
}

mem SocketAddrV4 {
	Ipv4Addr ip
    u16      port
}

impl SocketAddr for SocketAddrV4 {
	fn isv4() i32 {
		return true
	}
}