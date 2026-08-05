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

// Mother TcpStream::connect. Returns (err, stream_bits).
// Cross-pkg (i32, Mem) drops pointer fields; concurrent connect must not share
// a process-global LAST slot (MT clients race and cross-wire fds).
const TcpStream::connect(addr<net.SocketAddr>) i32, u64 {
	err<i32>, fd<i32> = nsys.new_for_addr(addr)
	if err != io.Ok {
		return err, 0.(u64)
	}
	stream<TcpStream> = TcpStream::fromrawfd(fd)
	err = nsys.connect_fd(stream.raw_fd(), addr)
	if err != io.Ok {
		return err, 0.(u64)
	}
	return io.Ok, stream.(u64)
}

// Package bridge — asyncio member async connect must not call
// nettcp.TcpStream::connect by static name (same leaf name corrupts the frame).
fn tcp_stream_connect(addr<net.SocketAddr>) i32, u64 {
	e<i32> = 0
	bits<u64> = 0
	e, bits = TcpStream::connect(addr)
	return e, bits
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

// Bypass io.Read/Write api dyn (defaults return Uncategorized).
TcpStream::read_priv(buf<io.Buf>) i32, u64 {
	std_s<net.TcpStream> = this.std_stream()
	e<i32> = 0
	n<u64> = 0
	e, n = libsys.tcp_stream_read_bits(std_s.asinner_bits(), buf)
	return e, n
}

TcpStream::write_priv(buf<io.Buf>) i32, u64 {
	std_s<net.TcpStream> = this.std_stream()
	e<i32> = 0
	n<u64> = 0
	e, n = libsys.tcp_stream_write_bits(std_s.asinner_bits(), buf)
	return e, n
}

fn tcp_stream_read_priv(s<TcpStream>, buf<io.Buf>) i32, u64 {
	e<i32> = 0
	n<u64> = 0
	e, n = s.read_priv(buf)
	return e, n
}

fn tcp_stream_write_priv(s<TcpStream>, buf<io.Buf>) i32, u64 {
	e<i32> = 0
	n<u64> = 0
	e, n = s.write_priv(buf)
	return e, n
}

// Read into a raw pointer (avoids io.Buf view / .len traps in FileDesc::read_io).
TcpStream::read_raw(dst<u8*>, len<u64>) i32, u64 {
	fd<i32> = this.raw_fd()
	raw<i64> = libsys.read(fd, dst, len)
	ri<i32> = 0
	ri = raw
	err<i32>, n<u64> = libsys.cvt(ri)
	ok_code<i32> = 1
	if err != ok_code return err, 0
	return ok_code, n
}

fn tcp_stream_read_raw(s<TcpStream>, dst<u8*>, len<u64>) i32, u64 {
	e<i32> = 0
	n<u64> = 0
	e, n = s.read_raw(dst, len)
	return e, n
}

impl io.Read for TcpStream {
	fn read(buf<io.Buf>) i32, u64 {
		e<i32> = 0
		n<u64> = 0
		e, n = this.read_priv(buf)
		return e, n
	}
}

impl io.Write for TcpStream {
	fn write(buf<io.Buf>) i32, u64 {
		e<i32> = 0
		n<u64> = 0
		e, n = this.write_priv(buf)
		return e, n
	}
	fn flush() i32 {
		return io.Ok
	}
}

impl event.Source for TcpStream {
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
