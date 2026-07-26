use io
use net
use string
use std
use sys
use netio.sys as nsys

fn path_offset(sockaddr<sys.SockaddrUn>) i32 {
	base<u64> = sockaddr
	path<u64> = &sockaddr.sun_path
	return path - base
}

fn socket_addr(path<string.String>) i32, sys.SockaddrUn, i32 {
	sockaddr<sys.SockaddrUn> = new sys.SockaddrUn {}
	sockaddr.sun_family = sys.AF_UNIX
	bytes<u8*> = path.str()
	length<i32> = std.strlen(bytes)
	if length >= sys.SUN_PATH_LEN
		return io.InvalidInputPathShorterSunLen, null, 0

	i<i32> = 0
	while i < length {
		sockaddr.sun_path[i] = bytes[i]
		i += 1
	}

	offset<i32> = path_offset(sockaddr)
	socklen<i32> = offset + length + 1
	return nsys.Ok, sockaddr, socklen
}

fn socket_pair(flags<i32>) i32, net.UnixStream, net.UnixStream {
	fds<i32*> = new 8
	nb<i32> = 0x800
	ce<i32> = 0x80000
	err<i32> = sys.cvt(sys.socketpair(sys.AF_UNIX, flags | nb | ce, 0, fds))
	if err != nsys.Ok
		return err, null, null
	return nsys.Ok, stream_from_fd(fds[0]), stream_from_fd(fds[1])
}

fn stream_from_fd(fd<i32>) net.UnixStream {
	return new net.UnixStream {
		socket_hub: new sys.Socket {
			desc: sys.FileDesc::from_raw_fd(fd)
		}
	}
}

fn listener_from_fd(fd<i32>) net.UnixListener {
	return new net.UnixListener {
		socket_hub: new sys.Socket {
			desc: sys.FileDesc::from_raw_fd(fd)
		}
	}
}

fn datagram_from_fd(fd<i32>) net.UnixDatagram {
	return new net.UnixDatagram {
		socket_hub: new sys.Socket {
			desc: sys.FileDesc::from_raw_fd(fd)
		}
	}
}
