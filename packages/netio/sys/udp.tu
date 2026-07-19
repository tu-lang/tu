use netio
use net
use sys as libsys

fn udp_bind(addr<net.SocketAddr>) i32, net.UdpSocket {
	err<i32>, fd<i32> = new_ip_socket(addr, libsys.SOCK_DGRAM)
	if err != libsys.Ok
		return err, null

	ptr_bits<u64>, raw_len<i32> = socket_addr(addr)
	cerr<i32>, junk<u64> = libsys.cvt(libsys.bind(fd, ptr_bits, raw_len))
	if cerr != libsys.Ok {
		libsys.close(fd)
		return cerr, null
	}
	return libsys.Ok, net.UdpSocket::fromrawfd(fd)
}
