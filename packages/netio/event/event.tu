use netio
use netio.sys

mem Event {
	sys.Event* inner
}

const Event::token() netio.Token {
	return sys.event_token(this.inner)
}

const Event::is_readable() bool {
	return sys.event_is_readable(this.inner)
}

const Event::is_writable() bool {
	return sys.event_is_writable(this.inner)
}

const Event::is_error() bool {
	return sys.event_is_error(this.inner)
}

const Event::is_read_closed() bool {
	return sys.event_is_read_closed(this.inner)
}

const Event::is_write_closed() bool {
	return sys.event_is_write_closed(this.inner)
}

const Event::is_priority() bool {
	return sys.event_is_priority(this.inner)
}

const Event::from_sys_event_ref(sys_event<sys.Event>) Event {
	return new Event { inner: sys_event }
}
