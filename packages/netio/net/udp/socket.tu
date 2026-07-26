// Lives in package netio.net.udp (short-name `udp`) so `use net as libnet`
// does not poison getPackage for local mem types (parent short-name is `net`).

use netio
use io
use netio.event
use netio.sys as nsys
use net as libnet
use sys as libsys

// Tu: u64 + bridges.
// Linux do_io is identity — call through fd_holder / from_std socket.

mem UdpSocket {
	u64 iosrc_bits
}

const UdpSocket::bind(addr<libnet.SocketAddr>) i32, UdpSocket {
	err<i32>, socket<libnet.UdpSocket> = nsys.udp_bind(addr)
	if err != io.Ok
		return err, null
	return io.Ok, UdpSocket::from_std(socket)
}

const UdpSocket::from_std(socket<libnet.UdpSocket>) UdpSocket {
	u<UdpSocket> = new UdpSocket
	u.iosrc_bits = netio.iosource_new_bits(socket.(u64), socket.as_raw_fd())
	return u
}

const UdpSocket::fromrawfd(fd<i32>) UdpSocket {
	return UdpSocket::from_std(libnet.UdpSocket::fromrawfd(fd))
}

UdpSocket::std_socket() libnet.UdpSocket {
	bits<u64> = netio.iosource_fd_holder_bits(this.iosrc_bits)
	return bits.(libnet.UdpSocket)
}

UdpSocket::send_to(buf<io.Buf>, target<libnet.SocketAddr>) i32, u64 {
	std_u<libnet.UdpSocket> = this.std_socket()
	err<i32>, n<u64> = std_u.send_to(buf, target)
	return err, n
}

UdpSocket::recv_from(buf<io.Buf>) i32, u64, libnet.SocketAddr {
	std_u<libnet.UdpSocket> = this.std_socket()
	err<i32>, n<u64>, addr<libnet.SocketAddr> = std_u.recv_from(buf)
	return err, n, addr
}

impl event.Source for UdpSocket {
	fn enroll(registry<netio.Registry>, t<netio.Token>, interests<netio.Interest>) i32 {
		return netio.iosource_register_bits(this.iosrc_bits, registry, t, interests)
	}
	fn reenroll(registry<netio.Registry>, t<netio.Token>, interests<netio.Interest>) i32 {
		return netio.iosource_reregister_bits(this.iosrc_bits, registry, t, interests)
	}
	fn detach(registry<netio.Registry>) i32 {
		return netio.iosource_deregister_bits(this.iosrc_bits, registry)
	}
}

fn udp_socket_from_bits(bits<u64>) UdpSocket {
	return bits.(UdpSocket)
}

fn udp_socket_to_bits(u<UdpSocket>) u64 {
	return u.(u64)
}
