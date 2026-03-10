use io
use net
use sys

SOCK_NONBLOCK<i32> = 0x800
SOCK_CLOEXEC<i32> = 0x80000

fn new_ip_socket(addr<net.SocketAddr>, socket_type<i32>) i32, i32 {
	match addr.v4() {
		true : return new_socket(sys.AF_INET, socket_type)
		false: return new_socket(sys.AF_INET6, socket_type)
	}
}

fn new_socket(domain<i32>, socket_type<i32>) i32, i32 {
	full_type<i32> = socket_type | SOCK_NONBLOCK | SOCK_CLOEXEC
	err<i32>, fd<i32> = sys.cvt(sys_socket(domain, full_type, 0))
	return err, fd
}

mem SocketAddrCRepr {
	u64 raw
	u64 raw_len
}

fn socket_addr(addr<net.SocketAddr>) SocketAddrCRepr, i32 {
	raw_addr<u64>, raw_len<i32> = addr.into_inner()
	return new SocketAddrCRepr {
		raw: raw_addr,
		raw_len: raw_len
	}, raw_len
}

SocketAddrCRepr::as_ptr() u64 {
	return this.raw
}

fn to_socket_addr(storage<sys.SockaddrStorage>) i32, net.SocketAddr {
	return sys.sockaddr_to_addr(storage, sizeof(sys.SockaddrStorage))
}
