use netio
use netio.event
use netio.sys as nsys
use string
use net
use io
use sys as libsys
use netio.sys.uds as sysuds

mem UnixListener {
	u64 iosrc_bits
}

const UnixListener::bind(path<string.String>) i32, UnixListener {
	err<i32>, listener<net.UnixListener> = sysuds.bind(path)
	if err != io.Ok
		return err, null
	return io.Ok, UnixListener::from_std(listener)
}

const UnixListener::from_std(listener<net.UnixListener>) UnixListener {
	l<UnixListener> = new UnixListener
	l.iosrc_bits = netio.iosource_new_bits(listener.(u64), listener.as_raw_fd())
	return l
}

UnixListener::std_listener() net.UnixListener {
	bits<u64> = netio.iosource_fd_holder_bits(this.iosrc_bits)
	return bits.(net.UnixListener)
}

UnixListener::accept() i32, UnixStream, sysuds.SocketAddr {
	std_l<net.UnixListener> = this.std_listener()
	err<i32>, std_stream<net.UnixStream>, addr<sysuds.SocketAddr> = sysuds.accept(std_l)
	if err != io.Ok
		return err, null, null
	return io.Ok, UnixStream::from_std(std_stream), addr
}

impl event.Source for UnixListener {
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
