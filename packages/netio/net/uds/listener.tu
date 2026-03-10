use netio
use netio.event
use netio.sys
use string
use net
use sys.uds

mem UnixListener {
	netio.IoSource* inner
}

const UnixListener::bind(path<string.String>) i32, UnixListener {
	err<i32>, listener<net.UnixListener> = uds.bind(path)
	if err != Ok
		return err, null
	return Ok, new UnixListener {
		inner: netio.IoSource::new(listener)
	}
}

const UnixListener::from_std(listener<net.UnixListener>) UnixListener {
	return new UnixListener { inner: netio.IoSource::new(listener) }
}

UnixListener::accept() i32, UnixStream, uds.SocketAddr {
	err<i32>, std_stream<net.UnixStream>, addr<uds.SocketAddr> = uds.accept(this.inner.inner)
	if err != Ok
		return err, null, null
	return Ok, UnixStream::from_std(std_stream), addr
}

impl event.Source for UnixListener {
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
