use netio
use io
use net
use runtime
use sys as libsys

fn new_for_addr(address<net.SocketAddr>) i32, i32 {
	if net.socket_addr_is_v4(address) {
		err<i32>, fd<i32> = new_socket(libsys.AF_INET, libsys.SOCK_STREAM)
		return err, fd
	}
	err<i32>, fd<i32> = new_socket(libsys.AF_INET6, libsys.SOCK_STREAM)
	return err, fd
}

fn bind(socket<net.TcpListener>, addr<net.SocketAddr>) i32 {
	raw_addr<SocketAddrCRepr>, raw_len<i32> = socket_addr(addr)
	err<i32>, junk<u64> = libsys.cvt(sys_bind(socket.as_raw_fd(), raw_addr.as_ptr(), raw_len))
	return err
}

fn connect(socket<net.TcpStream>, addr<net.SocketAddr>) i32 {
	raw_addr<SocketAddrCRepr>, raw_len<i32> = socket_addr(addr)
	err<i32>, junk<u64> = libsys.cvt(sys_connect(socket.as_raw_fd(), raw_addr.as_ptr(), raw_len))
	if err != Ok && err != io.OS_EINPROGRESS
		return err
	return Ok
}

fn listen(socket<net.TcpListener>, backlog<u32>) i32 {
	backlog_i32<i32> = backlog.(i32)
	if backlog_i32 < 0
		backlog_i32 = runtime.I32_MAX
	err<i32>, junk<u64> = libsys.cvt(sys_listen(socket.as_raw_fd(), backlog_i32))
	return err
}

fn set_reuseaddr(socket<net.TcpListener>, reuseaddr<i32>) i32 {
	val<i32> = 0
	if reuseaddr != 0
		val = 1
	return libsys.setsockopt(socket.asinner().socket(), libsys.SOL_SOCKET, libsys.SO_REUSEADDR, val.(u64), 4)
}

fn accept(listener<net.TcpListener>) i32, net.TcpStream, net.SocketAddr {
	storage<libsys.SockaddrStorage> = new libsys.SockaddrStorage{}
	length<i32> = sizeof(libsys.SockaddrStorage)
	flags<i32> = libsys.SOCK_CLOEXEC | libsys.SOCK_NONBLOCK
	err<i32>, fd<u64> = libsys.cvt(sys_accept4(listener.as_raw_fd(), storage, length, flags))
	if err != Ok
		return err, null, null
	stream<net.TcpStream> = net.TcpStream::fromrawfd(fd.(i32))
	aerr<i32>, addr<net.SocketAddr> = libsys.sockaddr_to_addr(storage, length.(u64))
	if aerr != Ok
		return aerr, null, null
	return Ok, stream, addr
}
