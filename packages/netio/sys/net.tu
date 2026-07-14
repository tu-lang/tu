use io
use net
use sys as libsys

SOCK_NONBLOCK<i32> = 0x800
SOCK_CLOEXEC<i32> = 0x80000

fn new_ip_socket(addr<net.SocketAddr>, socket_type<i32>) i32, i32 {
	if net.socket_addr_is_v4(addr) {
		err<i32>, fd<i32> = new_socket(libsys.AF_INET, socket_type)
		return err, fd
	}
	err<i32>, fd<i32> = new_socket(libsys.AF_INET6, socket_type)
	return err, fd
}

fn new_socket(domain<i32>, socket_type<i32>) i32, i32 {
	full_type<i32> = socket_type | SOCK_NONBLOCK | SOCK_CLOEXEC
	err<i32>, fd<u64> = libsys.cvt(libsys.socket(domain, full_type, 0))
	return err, fd.(i32)
}

// Mother: SocketAddrCRepr.as_ptr + socklen for bind/connect.
fn socket_addr(addr<net.SocketAddr>) u64, i32 {
	bits<u64>, len_u<u32> = net.socket_addr_into_inner_bits(addr)
	return libsys.socket_addr_crepr_as_ptr_raw(bits), len_u.(i32)
}

fn to_socket_addr(storage_bits<u64>) i32, net.SocketAddr {
	slen<i32> = libsys.SOCKADDR_STORAGE_LEN
	slen_u<u64> = slen.(u64)
	err<i32>, sa_bits<u64> = libsys.sockaddr_to_addr_raw(storage_bits, slen_u)
	return err, net.socket_addr_from_bits(sa_bits)
}
