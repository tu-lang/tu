use netio
use io
use net
use runtime
use sys

fn new_for_addr(address<net.SocketAddr>) i32, i32 {
	match address.v4() {
		true : return new_socket(sys.AF_INET, sys.SOCK_STREAM)
		false: return new_socket(sys.AF_INET6, sys.SOCK_STREAM)
	}
}

fn bind(socket<net.TcpListener>, addr<net.SocketAddr>) i32 {
	raw_addr<SocketAddrCRepr>, raw_len<i32> = socket_addr(addr)
	return sys.cvt(sys_bind(socket.as_raw_fd(), raw_addr.as_ptr(), raw_len))
}

fn connect(socket<net.TcpStream>, addr<net.SocketAddr>) i32 {
	raw_addr<SocketAddrCRepr>, raw_len<i32> = socket_addr(addr)
	err<i32> = sys.cvt(sys_connect(socket.as_raw_fd(), raw_addr.as_ptr(), raw_len))
	if err != Ok && err != io.OS_EINPROGRESS
		return err
	return Ok
}

fn listen(socket<net.TcpListener>, backlog<u32>) i32 {
	backlog_i32<i32> = backlog
	if backlog_i32 < 0
		backlog_i32 = runtime.I32_MAX
	return sys.cvt(sys_listen(socket.as_raw_fd(), backlog_i32))
}

fn set_reuseaddr(socket<net.TcpListener>, reuseaddr<bool>) i32 {
	val<i32> = 0
	if reuseaddr
		val = 1
	return sys.setsockopt(socket.asinner().socket(), sys.SOL_SOCKET, sys.SO_REUSEADDR, &val, sizeof(i32))
}

fn accept(listener<net.TcpListener>) i32, net.TcpStream, net.SocketAddr {
	storage<sys.SockaddrStorage> = new sys.SockaddrStorage {}
	length<i32> = sizeof(sys.SockaddrStorage)
	flags<i32> = sys.SOCK_CLOEXEC | sys.SOCK_NONBLOCK
	err<i32>, fd<i32> = sys.cvt(sys_accept4(listener.as_raw_fd(), storage, &length, flags))
	if err != Ok
		return err, null, null
	stream<net.TcpStream> = net.TcpStream::fromrawfd(fd)
	err, addr<net.SocketAddr> = sys.sockaddr_to_addr(storage, length)
	if err != Ok
		return err, null, null
	return Ok, stream, addr
}
