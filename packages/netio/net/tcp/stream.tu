use netio
use io
use netio.event
use netio.sys
use net

mem TcpStream {
	netio.IoSource* inner
}

const TcpStream::connect(addr<net.SocketAddr>) i32, TcpStream {
	err<i32>, fd<i32> = sys.new_for_addr(addr)
	if err != Ok
		return err, null
	stream<TcpStream> = new TcpStream {
		inner: netio.IoSource::new(net.TcpStream::fromrawfd(fd))
	}
	err = sys.connect(stream.inner.inner, addr)
	if err != Ok
		return err, null
	return Ok, stream
}

const TcpStream::from_std(stream<net.TcpStream>) TcpStream {
	return new TcpStream { inner: netio.IoSource::new(stream) }
}

TcpStream::shutdown(how<i32>) i32 {
	return this.inner.inner.shutdown(how)
}

TcpStream::take_error() i32, i32, i32 {
	return this.inner.inner.take_error()
}

impl io.Read for TcpStream {
	fn read(buf<io.Buf>) i32, u64 {
		return this.inner.inner.read(buf)
	}
}

impl io.Write for TcpStream {
	fn write(buf<io.Buf>) i32, u64 {
		return this.inner.inner.write(buf)
	}
	fn flush() i32 {
		return Ok
	}
}

impl event.Source for TcpStream {
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
