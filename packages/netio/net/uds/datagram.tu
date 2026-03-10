use netio
use io
use netio.event
use netio.sys
use net
use sys.uds

mem UnixDatagram {
	netio.IoSource* inner
}

const UnixDatagram::bind(path<string.String>) i32, UnixDatagram {
	err<i32>, socket<net.UnixDatagram> = uds.bind(path)
	if err != Ok
		return err, null
	return Ok, new UnixDatagram { inner: netio.IoSource::new(socket) }
}

const UnixDatagram::from_std(socket<net.UnixDatagram>) UnixDatagram {
	return new UnixDatagram { inner: netio.IoSource::new(socket) }
}

UnixDatagram::recv_from(buf<io.Buf>) i32, u64, uds.SocketAddr {
	return uds.recv_from(this.inner.inner, buf)
}

UnixDatagram::recv(buf<io.Buf>) i32, u64 {
	return this.inner.inner.recv(buf.ptr())
}

UnixDatagram::send_to(buf<io.Buf>, path<string.String>) i32, u64 {
	return this.inner.inner.send_to(buf, path)
}

impl event.Source for UnixDatagram {
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
