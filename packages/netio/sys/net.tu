use io
use net
use sys as libsys

SOCK_NONBLOCK<i32> = 0x800
SOCK_CLOEXEC<i32> = 0x80000

fn new_ip_socket(addr<net.SocketAddr>, socket_type<i32>) i32, i32 {
	if addr.v4() {
		err<i32>, fd<i32> = new_socket(libsys.AF_INET, socket_type)
		return err, fd
	}
	err<i32>, fd<i32> = new_socket(libsys.AF_INET6, socket_type)
	return err, fd
}

fn new_socket(domain<i32>, socket_type<i32>) i32, i32 {
	full_type<i32> = socket_type | SOCK_NONBLOCK | SOCK_CLOEXEC
	err<i32>, fd<u64> = libsys.cvt(sys_socket(domain, full_type, 0))
	return err, fd.(i32)
}

mem SocketAddrCRepr {
	u64 raw
	u64 raw_len
}

fn socket_addr(addr<net.SocketAddr>) SocketAddrCRepr, i32 {
	repr<libsys.SocketAddrCRepr>, len<u32> = addr.into_inner()
	wrap<SocketAddrCRepr> = new SocketAddrCRepr
	wrap.raw = repr.(u64)
	wrap.raw_len = len.(u64)
	return wrap, len.(i32)
}

SocketAddrCRepr::as_ptr() u64 {
	return this.raw
}

fn to_socket_addr(storage<libsys.SockaddrStorage>) i32, net.SocketAddr {
	err<i32>, sa<net.SocketAddr> = libsys.sockaddr_to_addr(storage, sizeof(libsys.SockaddrStorage))
	return err, sa
}
