use io
use netio.sys

mem Events {
	sys.Events* hub
}

mem Iter {
	Events* events
	u64 pos
}

// Raw-bits Events decode for callers outside this package.
fn events_from_bits(bits<u64>) Events {
    return bits.(Events)
}

// Package-level constructor for cross-package callers.
fn make_events(capacity<u64>) Events {
    return Events::with_capacity(capacity)
}

const Events::with_capacity(capacity<u64>) Events {
	return new Events {
		hub: sys.Events::with_capacity(capacity)
	}
}

Events::iter() Iter {
	return new Iter {
		events: this,
		pos: 0
	}
}

Events::sys() sys.Events {
	return this.hub
}

Iter::next() i32, Event {
	wrap<Events> = this.events
	hub_ev<sys.Events> = wrap.sys()
	sys_event<sys.Event> = hub_ev.get(this.pos)
	this.pos += 1
	if sys_event == null
		return io.NotFound, null
	return io.Ok, Event::from_sys_event_ref(sys_event)
}

// Package-level iter bridge (avoids StaticCall on instance method).
fn events_begin_iter(ev<Events>) Iter {
    return new Iter {
        events: ev,
        pos: 0
    }
}

// Package-level next bridge (avoids StaticCall on instance method).
fn events_iter_next(it<Iter>) i32, Event {
    ie<i32> = 0
    ev<Event> = null
    ie, ev = it.next()
    return ie, ev
}

Iter::count() u64 {
	wrap<Events> = this.events
	hub_ev<sys.Events> = wrap.sys()
	return hub_ev.slot_count()
}
