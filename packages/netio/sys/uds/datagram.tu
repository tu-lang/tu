use netio
use io
use net
use string
use sys
use netio.sys as nsys

fn bind(path<string.String>) i32, net.UnixDatagram {
	err<i32>, fd<i32> = nsys.new_socket(sys.AF_UNIX, sys.SOCK_DGRAM)
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
	return nsys.Ok, datagram_from_fd(fd)
}

fn recv_from(socket<net.UnixDatagram>, dst<io.Buf>) i32, u64, SocketAddr {
	count<u64> = 0
	err<i32>, addr<SocketAddr> = SocketAddr::new(fn(raw_sockaddr, raw_len){
		err<i32>, n<i64> = sys.cvt(sys.recvfrom(socket.as_raw_fd(), dst.ptr(), dst.len(), 0, raw_sockaddr, raw_len))
		if err != nsys.Ok
			return err
		count = n
		return nsys.Ok
	})
	if err != nsys.Ok
		return err, 0, null
	return nsys.Ok, count, addr
}
