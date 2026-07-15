use netio.event
use io
use sys

// Mother: netio::sys::IoSourceState (linux). do_io just invokes the callback.
mem IoSourceState {
	i64 pad
}

const IoSourceState::new() IoSourceState {
	return new IoSourceState { pad: 0 }
}

IoSourceState::do_io(callable, io_bits<u64>) {
	return callable(io_bits)
}

// Mother: IoSource<T: AsRawFd>. Tu stores raw_fd + original object bits.
mem IoSource {
	IoSourceState* state
	i32 raw_fd
	u64 io_bits
	u64 selector_id
}

const IoSource::new(io_obj<AsRawFd>) IoSource {
	return new IoSource {
		state: IoSourceState::new(),
		raw_fd: io_obj.as_raw_fd(),
		io_bits: io_obj.(u64),
		selector_id: 0
	}
}

IoSource::do_io(callable) {
	return this.state.do_io(callable, this.io_bits)
}

IoSource::io_object_bits() u64 {
	return this.io_bits
}

IoSource::register(registry<Registry>, t<Token>, interests<Interest>) i32 {
	if this.selector_id != 0 && this.selector_id != registry.selector().id()
		return io.AlreadyExists
	this.selector_id = registry.selector().id()
	return registry.selector().register(this.raw_fd, t.as_u64(), interest_as_u8(interests))
}

IoSource::reregister(registry<Registry>, t<Token>, interests<Interest>) i32 {
	if this.selector_id == 0
		return io.NotFound
	if this.selector_id != registry.selector().id()
		return io.AlreadyExists
	return registry.selector().reregister(this.raw_fd, t.as_u64(), interest_as_u8(interests))
}

IoSource::deregister(registry<Registry>) i32 {
	if this.selector_id == 0
		return io.NotFound
	if this.selector_id != registry.selector().id()
		return io.AlreadyExists
	this.selector_id = 0
	return registry.selector().deregister(this.raw_fd)
}

fn iosource_new_bits(io_obj<AsRawFd>) u64 {
	src<IoSource> = IoSource::new(io_obj)
	return src.(u64)
}

fn iosource_do_io_bits(bits<u64>, callable) {
	src<IoSource> = bits.(IoSource)
	return src.do_io(callable)
}

// Recover the original held object bits (TcpStream / UdpSocket / ...).
fn iosource_fd_holder_bits(bits<u64>) u64 {
	src<IoSource> = bits.(IoSource)
	return src.io_object_bits()
}

fn iosource_register_bits(bits<u64>, registry<Registry>, t<Token>, interests<Interest>) i32 {
	src<IoSource> = bits.(IoSource)
	return src.register(registry, t, interests)
}

fn iosource_reregister_bits(bits<u64>, registry<Registry>, t<Token>, interests<Interest>) i32 {
	src<IoSource> = bits.(IoSource)
	return src.reregister(registry, t, interests)
}

fn iosource_deregister_bits(bits<u64>, registry<Registry>) i32 {
	src<IoSource> = bits.(IoSource)
	return src.deregister(registry)
}
