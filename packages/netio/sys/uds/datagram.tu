use netio
use io
use net
use string
use sys

fn bind(path<string.String>) i32, net.UnixDatagram {
	err<i32>, fd<i32> = netio.sys.new_socket(sys.AF_UNIX, sys.SOCK_DGRAM)
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
	return Ok, net.UnixDatagram::fromrawfd(fd)
}

fn recv_from(socket<net.UnixDatagram>, dst<io.Buf>) i32, u64, SocketAddr {
	count<u64> = 0
	err<i32>, addr<SocketAddr> = SocketAddr::new(fn(raw_sockaddr, raw_len){
		err<i32>, n<i64> = sys.cvt(sys_recvfrom(socket.as_raw_fd(), dst.ptr(), dst.len(), 0, raw_sockaddr, raw_len))
		if err != Ok
			return err
		count = n
		return Ok
	})
	if err != Ok
		return err, 0, null
	return Ok, count, addr
}
