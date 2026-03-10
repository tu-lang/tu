use io
use net
use string
use sys

fn path_offset(sockaddr<sys.SockaddrUn>) i32 {
	base<u64> = sockaddr
	path<u64> = &sockaddr.sun_path
	return path - base
}

fn socket_addr(path<string.String>) i32, sys.SockaddrUn, i32 {
	sockaddr<sys.SockaddrUn> = new sys.SockaddrUn {}
	sockaddr.sun_family = sys.AF_UNIX
	bytes<u8*> = path.str()
	length<i32> = path.len()
	if length >= sizeof(sockaddr.sun_path)
		return io.InvalidInputPathShorterSunLen, null, 0

	i<i32> = 0
	while i < length {
		sockaddr.sun_path[i] = bytes[i]
		i += 1
	}

	offset<i32> = path_offset(sockaddr)
	socklen<i32> = offset + length + 1
	return Ok, sockaddr, socklen
}

fn pair(flags<i32>) i32, net.UnixStream, net.UnixStream {
	fds<i32*> = new 8
	err<i32> = sys.cvt(sys_socketpair(sys.AF_UNIX, flags | sys.SOCK_NONBLOCK | sys.SOCK_CLOEXEC, 0, fds))
	if err != Ok
		return err, null, null
	return Ok, net.UnixStream::fromrawfd(fds[0]), net.UnixStream::fromrawfd(fds[1])
}
