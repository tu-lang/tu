use io
use net
use sys as libsys

SOCK_NONBLOCK<i32> = 0x800
SOCK_CLOEXEC<i32> = 0x80000

// Library `sys` constants re-exported under this package's linker namespace.
// `use sys as libsys` still mangles `libsys.X` as netio_sys_X because this
// package's short name is also `sys` (constructor self-maps imports["sys"]).
Ok<i32>                   = 1
AF_INET<i32>              = 2
AF_INET6<i32>             = 10
SOCK_STREAM<i32>          = 1
SOCK_DGRAM<i32>           = 2
SOL_SOCKET<i32>           = 1
SO_REUSEADDR<i32>         = 2
SOCKADDR_STORAGE_LEN<i32> = 128
F_DUPFD_CLOEXEC<i32>      = 1030

fn new_ip_socket(addr<net.SocketAddr>, socket_type<i32>) i32, i32 {
	if net.socket_addr_is_v4(addr) {
		err<i32>, fd<i32> = new_socket(AF_INET, socket_type)
		return err, fd
	}
	err<i32>, fd<i32> = new_socket(AF_INET6, socket_type)
	return err, fd
}

fn new_socket(domain<i32>, socket_type<i32>) i32, i32 {
	// Keep args as typed locals: integer literals passed to native externs
	// are boxed by codegen and become EINVAL at the syscall boundary.
	nb<i32> = SOCK_NONBLOCK
	ce<i32> = SOCK_CLOEXEC
	full_type<i32> = socket_type | nb | ce
	proto<i32> = 0
	raw<i32> = libsys.socket(domain, full_type, proto)
	err<i32>, fd<u64> = libsys.cvt(raw)
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
