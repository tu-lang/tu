use string
use sys

mem SocketAddr {
	sys.SockaddrUn sockaddr
	i32 socklen
}

const SocketAddr::from_parts(sockaddr<sys.SockaddrUn>, socklen<i32>) SocketAddr {
	return new SocketAddr { sockaddr: sockaddr, socklen: socklen }
}

const SocketAddr::new(builder) i32, SocketAddr {
	sockaddr<sys.SockaddrUn> = new sys.SockaddrUn {}
	socklen<i32> = sizeof(sys.SockaddrUn)
	err<i32> = builder(sockaddr, &socklen)
	if err != Ok
		return err, null
	return Ok, SocketAddr::from_parts(sockaddr, socklen)
}

SocketAddr::as_pathname() string.String {
	if this.sockaddr.sun_path[0] == 0
		return ""
	return string.new(this.sockaddr.sun_path)
}
