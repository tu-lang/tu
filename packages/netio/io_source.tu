use netio.event.source
use netio.interest
use io
use netio.poll
use netio.sys
use netio
use sys

mem IoSource {
	sys.IoSourceState* state
	sys.AsRawFd inner
	u64 selector_id
}

const IoSource::new(io_obj<sys.AsRawFd>) IoSource {
	return new IoSource {
		state: sys.IoSourceState::new(),
		inner: io_obj,
		selector_id: 0
	}
}

IoSource::do_io(callable) {
	return this.state.do_io(callable, this.inner)
}

IoSource::register(registry<poll.Registry>, t<netio.Token>, interests<interest.Interest>) i32 {
	if this.selector_id != 0 && this.selector_id != registry.selector().id()
		return io.AlreadyExists
	this.selector_id = registry.selector().id()
	return registry.selector().register(this.inner.as_raw_fd(), t, interests)
}

IoSource::reregister(registry<poll.Registry>, t<netio.Token>, interests<interest.Interest>) i32 {
	if this.selector_id == 0
		return io.NotFound
	if this.selector_id != registry.selector().id()
		return io.AlreadyExists
	return registry.selector().reregister(this.inner.as_raw_fd(), t, interests)
}

IoSource::deregister(registry<poll.Registry>) i32 {
	if this.selector_id == 0
		return io.NotFound
	if this.selector_id != registry.selector().id()
		return io.AlreadyExists
	this.selector_id = 0
	return registry.selector().deregister(this.inner.as_raw_fd())
}
