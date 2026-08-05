use netio
use io
use net
use runtime
use sys as libsys

fn new_for_addr(address<net.SocketAddr>) i32, i32 {
	if net.socket_addr_is_v4(address) {
		// Use package SOCK_* — libsys.SOCK_* mangles under package short-name `sys`.
		err<i32>, fd<i32> = new_socket(AF_INET, SOCK_STREAM)
		return err, fd
	}
	err<i32>, fd<i32> = new_socket(AF_INET6, SOCK_STREAM)
	return err, fd
}

// Mother tcp::bind via as_raw_fd; fd variant avoids broken cross-pkg as_raw_fd.
fn tcp_bind_fd(fd<i32>, addr<net.SocketAddr>) i32 {
	ptr_bits<u64>, raw_len<i32> = socket_addr(addr)
	err<i32>, junk<u64> = libsys.cvt(libsys.bind(fd, ptr_bits, raw_len))
	return err
}

fn tcp_bind(socket<net.TcpListener>, addr<net.SocketAddr>) i32 {
	return tcp_bind_fd(socket.as_raw_fd(), addr)
}

fn connect_fd(fd<i32>, addr<net.SocketAddr>) i32 {
	ptr_bits<u64>, raw_len<i32> = socket_addr(addr)
	err<i32>, junk<u64> = libsys.cvt(libsys.connect(fd, ptr_bits, raw_len))
	if err != libsys.Ok && err != io.OS_EINPROGRESS
		return err
	return libsys.Ok
}

fn connect(socket<net.TcpStream>, addr<net.SocketAddr>) i32 {
	return connect_fd(socket.as_raw_fd(), addr)
}

fn listen_fd(fd<i32>, backlog<u32>) i32 {
	backlog_i32<i32> = backlog.(i32)
	if backlog_i32 < 0
		backlog_i32 = runtime.I32_MAX
	err<i32>, junk<u64> = libsys.cvt(libsys.listen(fd, backlog_i32))
	return err
}

fn listen(socket<net.TcpListener>, backlog<u32>) i32 {
	return listen_fd(socket.as_raw_fd(), backlog)
}

fn set_reuseaddr_fd(fd<i32>, reuseaddr<i32>) i32 {
	val<i32> = 0
	if reuseaddr != 0
		val = 1
	// Mother: setsockopt(..., &val, sizeof(c_int)). optval is a pointer.
	vp<i32*> = &val
	opt_ptr<u64> = vp.(u64)
	opt_len<u32> = 4
	level<i32> = SOL_SOCKET
	optname<i32> = SO_REUSEADDR
	sock_rc<i32> = libsys.setsockopt(fd, level, optname, opt_ptr, opt_len)
	err<i32>, junk<u64> = libsys.cvt(sock_rc)
	return err
}

fn set_reuseaddr(socket<net.TcpListener>, reuseaddr<i32>) i32 {
	return set_reuseaddr_fd(socket.as_raw_fd(), reuseaddr)
}

// accept_fd returns (err, std_stream_bits, addr_bits). No process-global LAST
// slot — MT / concurrent accept must not cross-wire fds.
fn accept(listener<net.TcpListener>) i32, u64, u64 {
	e<i32> = 0
	sb<u64> = 0
	ab<u64> = 0
	e, sb, ab = accept_fd(listener.as_raw_fd())
	return e, sb, ab
}

fn accept_fd(fd<i32>) i32, u64, u64 {
	storage_bits<u64> = libsys.sockaddr_storage_new_raw()
	length<i32> = libsys.SOCKADDR_STORAGE_LEN
	cloexec<i32> = SOCK_CLOEXEC
	nonblock<i32> = SOCK_NONBLOCK
	flags<i32> = cloexec | nonblock
	err<i32>, afd<u64> = libsys.cvt(libsys.accept4(fd, storage_bits, &length, flags))
	if err != libsys.Ok {
		return err, 0.(u64), 0.(u64)
	}
	std_stream<net.TcpStream> = net.TcpStream::fromrawfd(afd.(i32))
	aerr<i32>, addr_bits<u64> = libsys.sockaddr_to_addr_raw(storage_bits, length.(u64))
	if aerr != libsys.Ok {
		return aerr, 0.(u64), 0.(u64)
	}
	return libsys.Ok, std_stream.(u64), addr_bits
}
