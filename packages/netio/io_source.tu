use netio.event
use io
use netio.sys as nsys
use sys as libsys

mem IoSource {
	nsys.IoSourceState* state
	libsys.AsRawFd inner
	u64 selector_id
}

const IoSource::new(io_obj<libsys.AsRawFd>) IoSource {
	return new IoSource {
		state: nsys.IoSourceState::new(),
		inner: io_obj,
		selector_id: 0
	}
}

IoSource::do_io(callable) {
	return this.state.do_io(callable, this.inner)
}

IoSource::register(registry<Registry>, t<Token>, interests<Interest>) i32 {
	if this.selector_id != 0 && this.selector_id != registry.selector().id()
		return io.AlreadyExists
	this.selector_id = registry.selector().id()
	return registry.selector().register(this.inner.as_raw_fd(), t.as_u64(), interests.bits)
}

IoSource::reregister(registry<Registry>, t<Token>, interests<Interest>) i32 {
	if this.selector_id == 0
		return io.NotFound
	if this.selector_id != registry.selector().id()
		return io.AlreadyExists
	return registry.selector().reregister(this.inner.as_raw_fd(), t.as_u64(), interests.bits)
}

IoSource::deregister(registry<Registry>) i32 {
	if this.selector_id == 0
		return io.NotFound
	if this.selector_id != registry.selector().id()
		return io.AlreadyExists
	this.selector_id = 0
	return registry.selector().deregister(this.inner.as_raw_fd())
}
