use io
use netio.sys

mem Events {
	sys.Events* inner
}

mem Iter {
	Events* inner
	u64 pos
}

const Events::with_capacity(capacity<u64>) Events {
	return new Events {
		inner: sys.Events::with_capacity(capacity)
	}
}

Events::iter() Iter {
	return new Iter {
		inner: this,
		pos: 0
	}
}

Events::sys() sys.Events {
	return this.inner
}

Iter::next() i32, Event {
	sys_event<sys.Event> = this.inner.inner.get(this.pos)
	this.pos += 1
	if sys_event == null
		return io.NotFound, null
	return Ok, Event::from_sys_event_ref(sys_event)
}

Iter::count() u64 {
	return this.inner.inner.len()
}
