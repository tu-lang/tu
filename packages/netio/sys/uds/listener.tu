use netio
use net
use string
use sys
use netio.sys as nsys

fn bind(path<string.String>) i32, net.UnixListener {
	err<i32>, fd<i32> = nsys.new_socket(sys.AF_UNIX, sys.SOCK_STREAM)
	if err != nsys.Ok
		return err, null

	err, sockaddr<sys.SockaddrUn>, socklen<i32> = socket_addr(path)
	if err != nsys.Ok {
		sys.close(fd)
		return err, null
	}
	err = sys.cvt(sys.bind(fd, sockaddr, socklen))
	if err != nsys.Ok {
		sys.close(fd)
		return err, null
	}
	err = sys.cvt(sys.listen(fd, 1024))
	if err != nsys.Ok {
		sys.close(fd)
		return err, null
	}
	return nsys.Ok, listener_from_fd(fd)
}

fn accept(listener<net.UnixListener>) i32, net.UnixStream, SocketAddr {
	sockaddr<sys.SockaddrUn> = new sys.SockaddrUn {}
	socklen<i32> = sizeof(sys.SockaddrUn)
	flags<i32> = nsys.SOCK_NONBLOCK | nsys.SOCK_CLOEXEC
	err<i32>, fd<i32> = sys.cvt(sys.accept4(listener.as_raw_fd(), sockaddr, &socklen, flags))
	if err != nsys.Ok
		return err, null, null
	stream<net.UnixStream> = stream_from_fd(fd)
	return nsys.Ok, stream, SocketAddr::from_parts(sockaddr, socklen)
}
