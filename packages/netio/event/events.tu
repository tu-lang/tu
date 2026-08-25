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

// Named hub_events — never Events::sys / .sys(): `sys` is a type-assert trap
// under `use netio.sys`, so `.sys()` was casting the wrapper to sys.Events
// (wrong layout). epoll_wait then wrote into the wrapper and set_count never
// reached the real hub; Iter always saw count==0 and dropped every event.
Events::hub_events() sys.Events {
	return this.hub
}

// Package bridge for Poll / Driver (avoid MemberCall named sys).
fn events_hub(ev<Events>) sys.Events {
	return ev.hub
}

Iter::next() i32, Event {
	wrap<Events> = this.events
	hub_ev<sys.Events> = events_hub(wrap)
	// Bounds first: mem==null compares are unreliable for get() sentinel.
	if this.pos >= hub_ev.slot_count() {
		return io.NotFound, null
	}
	sys_event<sys.Event> = hub_ev.get(this.pos)
	this.pos += 1
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
	hub_ev<sys.Events> = events_hub(wrap)
	return hub_ev.slot_count()
}
