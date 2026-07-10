use netio
use net
use sys as libsys

fn bind(addr<net.SocketAddr>) i32, net.UdpSocket {
	err<i32>, fd<i32> = new_ip_socket(addr, libsys.SOCK_DGRAM)
	if err != Ok
		return err, null

	raw_addr<SocketAddrCRepr>, raw_len<i32> = socket_addr(addr)
	err = libsys.cvt(sys_bind(fd, raw_addr.as_ptr(), raw_len))
	if err != Ok {
		sys_close(fd)
		return err, null
	}
	return Ok, net.UdpSocket::fromrawfd(fd)
}
