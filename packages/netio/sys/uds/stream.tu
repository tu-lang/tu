use netio
use io
use net
use string
use sys

fn connect(path<string.String>) i32, net.UnixStream {
	err<i32>, fd<i32> = netio.sys.new_socket(sys.AF_UNIX, sys.SOCK_STREAM)
	if err != Ok
		return err, null
	err, sockaddr<sys.SockaddrUn>, socklen<i32> = socket_addr(path)
	if err != Ok {
		sys.close(fd)
		return err, null
	}
	err = sys.cvt(sys.connect(fd, sockaddr, socklen))
	if err != Ok && err != io.WouldBlock {
		sys.close(fd)
		return err, null
	}
	return Ok, net.UnixStream::fromrawfd(fd)
}

fn pair() i32, net.UnixStream, net.UnixStream {
	err<i32>, left<net.UnixStream>, right<net.UnixStream> = socket_pair(sys.SOCK_STREAM)
	return err, left, right
}
