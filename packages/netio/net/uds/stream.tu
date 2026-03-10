use netio
use io
use netio.event
use netio.sys
use string
use net
use sys.uds

mem UnixStream {
	netio.IoSource* inner
}

const UnixStream::connect(path<string.String>) i32, UnixStream {
	err<i32>, stream<net.UnixStream> = uds.connect(path)
	if err != Ok
		return err, null
	return Ok, new UnixStream { inner: netio.IoSource::new(stream) }
}

const UnixStream::from_std(stream<net.UnixStream>) UnixStream {
	return new UnixStream { inner: netio.IoSource::new(stream) }
}

const UnixStream::pair() i32, UnixStream, UnixStream {
	err<i32>, left<net.UnixStream>, right<net.UnixStream> = uds.pair()
	if err != Ok
		return err, null, null
	return Ok, UnixStream::from_std(left), UnixStream::from_std(right)
}

UnixStream::take_error() i32, i32, i32 {
	return this.inner.inner.take_error()
}

UnixStream::shutdown(how<i32>) i32 {
	return this.inner.inner.shutdown(how)
}

impl io.Read for UnixStream {
	fn read(buf<io.Buf>) i32, u64 {
		return this.inner.inner.read(buf)
	}
}

impl io.Write for UnixStream {
	fn write(buf<io.Buf>) i32, u64 {
		return this.inner.inner.write(buf)
	}
	fn flush() i32 {
		return Ok
	}
}

impl event.Source for UnixStream {
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
