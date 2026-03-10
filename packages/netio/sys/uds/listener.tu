use netio
use net
use string
use sys

fn bind(path<string.String>) i32, net.UnixListener {
	err<i32>, fd<i32> = netio.sys.new_socket(sys.AF_UNIX, sys.SOCK_STREAM)
	if err != Ok
		return err, null

	err, sockaddr<sys.SockaddrUn>, socklen<i32> = socket_addr(path)
	if err != Ok {
		sys_close(fd)
		return err, null
	}
	err = sys.cvt(sys_bind(fd, sockaddr, socklen))
	if err != Ok {
		sys_close(fd)
		return err, null
	}
	err = sys.cvt(sys_listen(fd, 1024))
	if err != Ok {
		sys_close(fd)
		return err, null
	}
	return Ok, net.UnixListener::fromrawfd(fd)
}

fn accept(listener<net.UnixListener>) i32, net.UnixStream, SocketAddr {
	sockaddr<sys.SockaddrUn> = new sys.SockaddrUn {}
	socklen<i32> = sizeof(sys.SockaddrUn)
	flags<i32> = sys.SOCK_NONBLOCK | sys.SOCK_CLOEXEC
	err<i32>, fd<i32> = sys.cvt(sys_accept4(listener.as_raw_fd(), sockaddr, &socklen, flags))
	if err != Ok
		return err, null, null
	stream<net.UnixStream> = net.UnixStream::fromrawfd(fd)
	return Ok, stream, SocketAddr::from_parts(sockaddr, socklen)
}
