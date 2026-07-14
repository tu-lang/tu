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
	ptr_bits<u64>, raw_len<i32> = socket_addr(addr)
	err<i32>, junk<u64> = libsys.cvt(libsys.bind(socket.as_raw_fd(), ptr_bits, raw_len))
	return err
}

fn connect(socket<net.TcpStream>, addr<net.SocketAddr>) i32 {
	ptr_bits<u64>, raw_len<i32> = socket_addr(addr)
	err<i32>, junk<u64> = libsys.cvt(libsys.connect(socket.as_raw_fd(), ptr_bits, raw_len))
	if err != libsys.Ok && err != io.OS_EINPROGRESS
		return err
	return libsys.Ok
}

fn listen(socket<net.TcpListener>, backlog<u32>) i32 {
	backlog_i32<i32> = backlog.(i32)
	if backlog_i32 < 0
		backlog_i32 = runtime.I32_MAX
	err<i32>, junk<u64> = libsys.cvt(libsys.listen(socket.as_raw_fd(), backlog_i32))
	return err
}

fn set_reuseaddr(socket<net.TcpListener>, reuseaddr<i32>) i32 {
	val<i32> = 0
	if reuseaddr != 0
		val = 1
	// Mother: socket.inner.socket(); as_raw_fd is the same FD.
	return libsys.setsockopt(socket.as_raw_fd(), libsys.SOL_SOCKET, libsys.SO_REUSEADDR, val.(u64), 4)
}

fn accept(listener<net.TcpListener>) i32, net.TcpStream, net.SocketAddr {
	storage_bits<u64> = libsys.sockaddr_storage_new_raw()
	length<i32> = libsys.SOCKADDR_STORAGE_LEN
	flags<i32> = libsys.SOCK_CLOEXEC | libsys.SOCK_NONBLOCK
	err<i32>, fd<u64> = libsys.cvt(libsys.accept4(listener.as_raw_fd(), storage_bits, &length, flags))
	if err != libsys.Ok
		return err, null, null
	stream<net.TcpStream> = net.TcpStream::fromrawfd(fd.(i32))
	aerr<i32>, addr_bits<u64> = libsys.sockaddr_to_addr_raw(storage_bits, length.(u64))
	if aerr != libsys.Ok
		return aerr, null, null
	return libsys.Ok, stream, net.socket_addr_from_bits(addr_bits)
}
