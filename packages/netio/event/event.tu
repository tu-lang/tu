use netio.sys

mem Event {
	sys.Event* event_hub
}

Event::token() u64 {
	return sys.event_token_bits(this.event_hub)
}

Event::is_readable() i32 {
	return sys.event_is_readable(this.event_hub)
}

Event::is_writable() i32 {
	return sys.event_is_writable(this.event_hub)
}

Event::is_error() i32 {
	return sys.event_is_error(this.event_hub)
}

Event::is_read_closed() i32 {
	return sys.event_is_read_closed(this.event_hub)
}

Event::is_write_closed() i32 {
	return sys.event_is_write_closed(this.event_hub)
}

Event::is_priority() i32 {
	return sys.event_is_priority(this.event_hub)
}

const Event::from_sys_event_ref(sys_event<sys.Event>) Event {
	return new Event { event_hub: sys_event }
}
