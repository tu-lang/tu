use netio
use io
use netio.event
use netio.sys as nsys
use net
use sys as libsys

// Mother: TcpListener { inner: IoSource<net::TcpListener> }.
// Tu: IoSource lives in package netio; store raw bits + netio.*_bits bridges.

mem TcpListener {
	u64 iosrc_bits
}

// Mother TcpListener::bind — new_for_addr, fromrawfd, set_reuseaddr, bind, listen.
const TcpListener::bind(addr<net.SocketAddr>) i32, TcpListener {
	err<i32>, fd<i32> = nsys.new_for_addr(addr)
	if err != Ok
		return err, null
	listener<TcpListener> = TcpListener::fromrawfd(fd)
	// Mother: tcp::set_reuseaddr(&listener.inner, true) via IoSource Deref → net::TcpListener.
	std_l<net.TcpListener> = listener.std_listener()
	err = nsys.set_reuseaddr(std_l, 1)
	if err != Ok
		return err, null
	err = nsys.bind(std_l, addr)
	if err != Ok
		return err, null
	err = nsys.listen(std_l, 1024)
	if err != Ok
		return err, null
	return Ok, listener
}

const TcpListener::from_std(listener<net.TcpListener>) TcpListener {
	l<TcpListener> = new TcpListener
	l.iosrc_bits = netio.iosource_new_bits(listener)
	return l
}

const TcpListener::fromrawfd(fd<i32>) TcpListener {
	return TcpListener::from_std(net.TcpListener::fromrawfd(fd))
}

// Mother Deref of IoSource → net::TcpListener.
TcpListener::std_listener() net.TcpListener {
	bits<u64> = netio.iosource_fd_holder_bits(this.iosrc_bits)
	return bits.(net.TcpListener)
}

// Mother: self.inner.do_io(|inner| tcp::accept(inner)...).
// Linux IoSourceState::do_io is a direct call; invoke accept on Deref target.
TcpListener::accept() i32, TcpStream, net.SocketAddr {
	std_l<net.TcpListener> = this.std_listener()
	err<i32>, std_stream<net.TcpStream>, addr<net.SocketAddr> = nsys.accept(std_l)
	if err != Ok
		return err, null, null
	return Ok, TcpStream::from_std(std_stream), addr
}

impl event.Source for TcpListener {
	fn register(registry<netio.Registry>, t<netio.Token>, interests<netio.Interest>) i32 {
		return netio.iosource_register_bits(this.iosrc_bits, registry, t, interests)
	}
	fn reregister(registry<netio.Registry>, t<netio.Token>, interests<netio.Interest>) i32 {
		return netio.iosource_reregister_bits(this.iosrc_bits, registry, t, interests)
	}
	fn deregister(registry<netio.Registry>) i32 {
		return netio.iosource_deregister_bits(this.iosrc_bits, registry)
	}
}
