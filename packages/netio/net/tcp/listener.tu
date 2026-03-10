use netio
use io
use netio.event
use netio.sys
use net

mem TcpListener {
	netio.IoSource* inner
}

const TcpListener::bind(addr<net.SocketAddr>) i32, TcpListener {
	err<i32>, fd<i32> = sys.new_for_addr(addr)
	if err != Ok
		return err, null
	listener<TcpListener> = new TcpListener {
		inner: netio.IoSource::new(net.TcpListener::fromrawfd(fd))
	}
	err = sys.set_reuseaddr(listener.inner.inner, true)
	if err != Ok
		return err, null
	err = sys.bind(listener.inner.inner, addr)
	if err != Ok
		return err, null
	err = sys.listen(listener.inner.inner, 1024)
	if err != Ok
		return err, null
	return Ok, listener
}

const TcpListener::from_std(listener<net.TcpListener>) TcpListener {
	return new TcpListener { inner: netio.IoSource::new(listener) }
}

TcpListener::accept() i32, TcpStream, net.SocketAddr {
	err<i32>, std_stream<net.TcpStream>, addr<net.SocketAddr> = sys.accept(this.inner.inner)
	if err != Ok
		return err, null, null
	return Ok, TcpStream::from_std(std_stream), addr
}

impl event.Source for TcpListener {
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
