use netio
use io
use netio.event
use netio.sys
use net as libnet

mem UdpSocket {
	netio.IoSource* inner
}

const UdpSocket::bind(addr<libnet.SocketAddr>) i32, UdpSocket {
	err<i32>, socket<libnet.UdpSocket> = sys.bind(addr)
	if err != Ok
		return err, null
	return Ok, new UdpSocket {
		inner: netio.IoSource::new(socket)
	}
}

const UdpSocket::from_std(socket<libnet.UdpSocket>) UdpSocket {
	return new UdpSocket { inner: netio.IoSource::new(socket) }
}

UdpSocket::send_to(buf<io.Buf>, target<libnet.SocketAddr>) i32, u64 {
	return this.inner.inner.send_to(buf, target)
}

UdpSocket::recv_from(buf<io.Buf>) i32, u64, libnet.SocketAddr {
	return this.inner.inner.recv_from(buf)
}

impl event.Source for UdpSocket {
	fn register(registry<netio.Registry>, t<netio.Token>, interests<netio.Interest>) i32 {
		return this.inner.register(registry, t, interests)
	}
	fn reregister(registry<netio.Registry>, t<netio.Token>, interests<netio.Interest>) i32 {
		return this.inner.reregister(registry, t, interests)
	}
	fn deregister(registry<netio.Registry>) i32 {
		return this.inner.deregister(registry)
	}
}
