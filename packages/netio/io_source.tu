use netio.event
use io
use sys
use netio.sys as nsys
use fmt

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

// Mother: IoSource<T: AsRawFd>. Tu stores raw_fd + original object bits
// (api AsRawFd cannot be a mem field / constructor param type slot).
mem IoSource {
	IoSourceState* state
	i32 raw_fd
	u64 io_bits
	u64 selector_id
}

const IoSource::new(fd<i32>, obj_bits<u64>) IoSource {
	st<IoSourceState> = IoSourceState::new()
	src<IoSource> = new IoSource
	src.state = st
	src.raw_fd = fd
	src.io_bits = obj_bits
	zero<u64> = 0
	src.selector_id = zero
	return src
}

IoSource::do_io(callable) {
	return this.state.do_io(callable, this.io_bits)
}

IoSource::io_object_bits() u64 {
	return this.io_bits
}

IoSource::register(registry<Registry>, t<Token>, interests<Interest>) i32 {
	sel<nsys.Selector> = registry_selector(registry)
	if this.selector_id != 0 && this.selector_id != sel.id()
		return io.AlreadyExists
	this.selector_id = sel.id()
	ret<i32> = sel.register(this.raw_fd, t.as_u64(), interest_as_u8(interests))
	return ret
}

IoSource::reregister(registry<Registry>, t<Token>, interests<Interest>) i32 {
	sel2<nsys.Selector> = registry_selector(registry)
	if this.selector_id == 0
		return io.NotFound
	if this.selector_id != sel2.id()
		return io.AlreadyExists
	return sel2.reregister(this.raw_fd, t.as_u64(), interest_as_u8(interests))
}

IoSource::deregister(registry<Registry>) i32 {
	sel3<nsys.Selector> = registry_selector(registry)
	if this.selector_id == 0
		return io.NotFound
	if this.selector_id != sel3.id()
		return io.AlreadyExists
	this.selector_id = 0
	return sel3.deregister(this.raw_fd)
}

// Mother IoSource::new(T): pass as_raw_fd() + object heap bits.
fn iosource_new_bits(obj_bits<u64>, fd<i32>) u64 {
	src<IoSource> = IoSource::new(fd, obj_bits)
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

fn iosource_raw_fd(bits<u64>) i32 {
	src<IoSource> = bits.(IoSource)
	return src.raw_fd
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
