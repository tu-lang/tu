use netio
use io
use netio.event
use netio.sys as nsys
use string
use net
use sys as libsys
use sys.uds

mem UnixStream {
	u64 iosrc_bits
}

const UnixStream::connect(path<string.String>) i32, UnixStream {
	err<i32>, stream<net.UnixStream> = uds.connect(path)
	if err != Ok
		return err, null
	return Ok, UnixStream::from_std(stream)
}

const UnixStream::from_std(stream<net.UnixStream>) UnixStream {
	s<UnixStream> = new UnixStream
	s.iosrc_bits = netio.iosource_new_bits(stream)
	return s
}

const UnixStream::pair() i32, UnixStream, UnixStream {
	err<i32>, left<net.UnixStream>, right<net.UnixStream> = uds.pair()
	if err != Ok
		return err, null, null
	return Ok, UnixStream::from_std(left), UnixStream::from_std(right)
}

UnixStream::std_stream() net.UnixStream {
	bits<u64> = netio.iosource_fd_holder_bits(this.iosrc_bits)
	return bits.(net.UnixStream)
}

UnixStream::take_error() i32, i32, i32 {
	std_s<net.UnixStream> = this.std_stream()
	ok<i32>, has<i32>, ret<i32> = std_s.take_error()
	return ok, has, ret
}

UnixStream::shutdown(how<i32>) i32 {
	std_s<net.UnixStream> = this.std_stream()
	return std_s.shutdown(how)
}

impl io.Read for UnixStream {
	fn read(buf<io.Buf>) i32, u64 {
		std_s<net.UnixStream> = this.std_stream()
		err<i32>, n<u64> = std_s.read(buf)
		return err, n
	}
}

impl io.Write for UnixStream {
	fn write(buf<io.Buf>) i32, u64 {
		std_s<net.UnixStream> = this.std_stream()
		err<i32>, n<u64> = std_s.write(buf)
		return err, n
	}
	fn flush() i32 {
		return Ok
	}
}

impl event.Source for UnixStream {
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
