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

LAST_TCP_STREAM<TcpStream> = null

fn tcp_stream_last() TcpStream {
	return LAST_TCP_STREAM
}

const TcpStream::from_std(stream<net.TcpStream>) TcpStream {
	return TcpStream::from_std_fd(stream, stream.as_raw_fd())
}

const TcpStream::from_std_fd(stream<net.TcpStream>, fd<i32>) TcpStream {
	s<TcpStream> = new TcpStream
	s.iosrc_bits = netio.iosource_new_bits(stream.(u64), fd)
	return s
}

const TcpStream::fromrawfd(fd<i32>) TcpStream {
	return TcpStream::from_std_fd(net.TcpStream::fromrawfd(fd), fd)
}

// Mother TcpStream::connect. Returns err only; on success tcp_stream_last().
const TcpStream::connect(addr<net.SocketAddr>) i32 {
	LAST_TCP_STREAM = null
	err<i32>, fd<i32> = nsys.new_for_addr(addr)
	if err != io.Ok
		return err
	stream<TcpStream> = TcpStream::fromrawfd(fd)
	err = nsys.connect_fd(stream.raw_fd(), addr)
	if err != io.Ok
		return err
	LAST_TCP_STREAM = stream
	return io.Ok
}

TcpStream::std_stream() net.TcpStream {
	bits<u64> = netio.iosource_fd_holder_bits(this.iosrc_bits)
	return bits.(net.TcpStream)
}

TcpStream::raw_fd() i32 {
	return netio.iosource_raw_fd(this.iosrc_bits)
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
