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

// Multi-ret (i32, TcpListener) drops the mem pointer across packages; publish
// the successful listener here (same pattern as IoDriver::new / LAST_IODRIVER).
LAST_TCP_LISTENER<TcpListener> = null

fn tcp_listener_last() TcpListener {
	return LAST_TCP_LISTENER
}

// Mother TcpListener::bind — new_for_addr, fromrawfd, set_reuseaddr, bind, listen.
// Returns err only; on success call tcp_listener_last() for the listener.
const TcpListener::bind(addr<net.SocketAddr>) i32 {
	LAST_TCP_LISTENER = null
	err<i32>, fd<i32> = nsys.new_for_addr(addr)
	if err != io.Ok
		return err
	listener<TcpListener> = TcpListener::fromrawfd(fd)
	one<i32> = 1
	err = nsys.set_reuseaddr_fd(fd, one)
	if err != io.Ok
		return err
	err = nsys.tcp_bind_fd(fd, addr)
	if err != io.Ok
		return err
	bl<u32> = 1024
	err = nsys.listen_fd(fd, bl)
	if err != io.Ok
		return err
	LAST_TCP_LISTENER = listener
	return io.Ok
}

const TcpListener::from_std(listener<net.TcpListener>) TcpListener {
	return TcpListener::from_std_fd(listener, listener.as_raw_fd())
}

const TcpListener::from_std_fd(listener<net.TcpListener>, fd<i32>) TcpListener {
	l<TcpListener> = new TcpListener
	bits<u64> = listener.(u64)
	l.iosrc_bits = netio.iosource_new_bits(bits, fd)
	return l
}

const TcpListener::fromrawfd(fd<i32>) TcpListener {
	nl<net.TcpListener> = net.TcpListener::fromrawfd(fd)
	return TcpListener::from_std_fd(nl, fd)
}

// Mother Deref of IoSource → net::TcpListener.
TcpListener::std_listener() net.TcpListener {
	bits<u64> = netio.iosource_fd_holder_bits(this.iosrc_bits)
	return bits.(net.TcpListener)
}

// Raw fd from the IoSource wrapper (avoids net.TcpListener::as_raw_fd cross-pkg).
TcpListener::raw_fd() i32 {
	return netio.iosource_raw_fd(this.iosrc_bits)
}

// Mother: self.inner.do_io(|inner| tcp::accept(inner)...).
// Linux IoSourceState::do_io is a direct call; invoke accept on Deref target.
// Multi-ret stream pointer is published via LAST_TCP_ACCEPT_STREAM.
LAST_TCP_ACCEPT_STREAM<TcpStream> = null
LAST_TCP_ACCEPT_ADDR<net.SocketAddr> = null

fn tcp_accept_stream_last() TcpStream {
	return LAST_TCP_ACCEPT_STREAM
}
fn tcp_accept_addr_last() net.SocketAddr {
	return LAST_TCP_ACCEPT_ADDR
}

TcpListener::accept() i32 {
	LAST_TCP_ACCEPT_STREAM = null
	LAST_TCP_ACCEPT_ADDR = null
	err<i32> = nsys.accept_fd(this.raw_fd())
	if err != io.Ok
		return err
	std_stream<net.TcpStream> = nsys.accept_stream_last()
	addr<net.SocketAddr> = nsys.accept_addr_last()
	LAST_TCP_ACCEPT_STREAM = TcpStream::from_std(std_stream)
	LAST_TCP_ACCEPT_ADDR = addr
	return io.Ok
}

impl event.Source for TcpListener {
	fn enroll(registry<netio.Registry>, t<netio.Token>, interests<netio.Interest>) i32 {
		fmt.println("tl_enroll")
		return netio.iosource_register_bits(this.iosrc_bits, registry, t, interests)
	}
	fn reenroll(registry<netio.Registry>, t<netio.Token>, interests<netio.Interest>) i32 {
		return netio.iosource_reregister_bits(this.iosrc_bits, registry, t, interests)
	}
	fn detach(registry<netio.Registry>) i32 {
		return netio.iosource_deregister_bits(this.iosrc_bits, registry)
	}
}
