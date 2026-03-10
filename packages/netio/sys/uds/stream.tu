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
		sys_close(fd)
		return err, null
	}
	err = sys.cvt(sys_connect(fd, sockaddr, socklen))
	if err != Ok && err != io.WouldBlock {
		sys_close(fd)
		return err, null
	}
	return Ok, net.UnixStream::fromrawfd(fd)
}

fn pair() i32, net.UnixStream, net.UnixStream {
	return pair(sys.SOCK_STREAM)
}
