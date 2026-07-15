use netio
use io
use netio.event
use netio.sys as nsys
use net
use sys as libsys

// Mother: TcpStream { inner: IoSource<net::TcpStream> }. Tu: u64 + netio bridges.
// Linux IoSourceState::do_io is a direct call — methods go through std_stream()
// (mother Deref of IoSource).

mem TcpStream {
	u64 iosrc_bits
}

const TcpStream::from_std(stream<net.TcpStream>) TcpStream {
	s<TcpStream> = new TcpStream
	s.iosrc_bits = netio.iosource_new_bits(stream.(u64), stream.as_raw_fd())
	return s
}

const TcpStream::fromrawfd(fd<i32>) TcpStream {
	return TcpStream::from_std(net.TcpStream::fromrawfd(fd))
}

const TcpStream::connect(addr<net.SocketAddr>) i32, TcpStream {
	err<i32>, fd<i32> = nsys.new_for_addr(addr)
	if err != io.Ok
		return err, null
	stream<TcpStream> = TcpStream::fromrawfd(fd)
	std_s<net.TcpStream> = stream.std_stream()
	err = nsys.connect(std_s, addr)
	if err != io.Ok
		return err, null
	return io.Ok, stream
}

TcpStream::std_stream() net.TcpStream {
	bits<u64> = netio.iosource_fd_holder_bits(this.iosrc_bits)
	return bits.(net.TcpStream)
}

TcpStream::shutdown(how<i32>) i32 {
	std_s<net.TcpStream> = this.std_stream()
	return std_s.shutdown(how)
}

TcpStream::take_error() i32, i32, i32 {
	std_s<net.TcpStream> = this.std_stream()
	ok<i32>, has<i32>, ret<i32> = std_s.take_error()
	return ok, has, ret
}

impl io.Read for TcpStream {
	fn read(buf<io.Buf>) i32, u64 {
		std_s<net.TcpStream> = this.std_stream()
		err<i32>, n<u64> = std_s.read(buf)
		return err, n
	}
}

impl io.Write for TcpStream {
	fn write(buf<io.Buf>) i32, u64 {
		std_s<net.TcpStream> = this.std_stream()
		err<i32>, n<u64> = std_s.write(buf)
		return err, n
	}
	fn flush() i32 {
		return io.Ok
	}
}

impl event.Source for TcpStream {
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
