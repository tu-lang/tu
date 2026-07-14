// epoll Selector (mother: netio/src/sys/epoll.rs).

use netio
use runtime
use std
use sys as libsys

// Linux x86_64 epoll / fcntl / close — declared in library/sys (symbols sys_*).
// Do not redeclare as sys_epoll_* here (package netio.sys → netio_sys_sys_epoll_*).

LOWEST_FD<i32> = 3
EPOLL_CLOEXEC<i32> = 0x80000
EPOLL_CTL_ADD<i32> = 1
EPOLL_CTL_DEL<i32> = 2
EPOLL_CTL_MOD<i32> = 3

EPOLLIN<u32> = 0x001
EPOLLPRI<u32> = 0x002
EPOLLOUT<u32> = 0x004
EPOLLERR<u32> = 0x008
EPOLLHUP<u32> = 0x010
EPOLLRDHUP<u32> = 0x2000
EPOLLET<u32> = 0x80000000

NEXT_SELECTOR_ID<u64> = 1

EVENT_SIZE<u64> = 16

mem Event {
	u32 flags
	u64 token
}

mem Events {
	Event* store
	u64 count
	u64 capacity_val
}

const Events::with_capacity(capacity<u64>) Events {
	ptr<u64> = std.malloc(EVENT_SIZE * capacity)
	return new Events { store: ptr.(Event), count: 0, capacity_val: capacity }
}

fn events_clear(evts<Events>) {
	evts.count = 0
}

fn events_as_mut_ptr(evts<Events>) Event {
	return evts.store
}

fn events_get_capacity(evts<Events>) u64 {
	return evts.capacity_val
}

fn events_set_count(evts<Events>, n<u64>) {
	evts.count = n
}

fn events_slot_count(evts<Events>) u64 {
	return evts.count
}

fn events_get(evts<Events>, pos<u64>) Event {
	if pos >= evts.count
		return null
	return evts.store + pos
}

Events::clear() {
	events_clear(this)
}

Events::as_mut_ptr() Event {
	return events_as_mut_ptr(this)
}

Events::get_capacity() u64 {
	return events_get_capacity(this)
}

Events::set_count(n<u64>) {
	events_set_count(this, n)
}

Events::slot_count() u64 {
	return events_slot_count(this)
}

Events::get(pos<u64>) Event {
	return events_get(this, pos)
}

mem Selector {
	u64 id
	i32 ep
	i32 has_waker
}

const Selector::new() i32, Selector {
	ep<i32> = libsys.epoll_create1(EPOLL_CLOEXEC)
	if ep == -1
		return libsys.last_error(), null
	id<u64> = NEXT_SELECTOR_ID
	NEXT_SELECTOR_ID += 1
	return libsys.Ok, new Selector {
		id: id,
		ep: ep,
		has_waker: 0
	}
}

fn selector_ep(sel<Selector>) i32 {
	return sel.ep
}

fn selector_id_bits(sel<Selector>) u64 {
	return sel.id
}

fn selector_has_waker(sel<Selector>) i32 {
	return sel.has_waker
}

fn selector_set_has_waker(sel<Selector>, v<i32>) {
	sel.has_waker = v
}

Selector::try_clone() i32, Selector {
	err<i32>, ep_u<u64> = libsys.cvt(libsys.fcntl(selector_ep(this), libsys.F_DUPFD_CLOEXEC, LOWEST_FD))
	if err != libsys.Ok
		return err, null
	ep2<i32> = ep_u.(i32)
	return libsys.Ok, new Selector {
		id: selector_id_bits(this),
		ep: ep2,
		has_waker: selector_has_waker(this)
	}
}

fn selector_select_impl(sel<Selector>, evts<Events>, timeout_ms_in<i32>) i32 {
	timeout_ms<i32> = timeout_ms_in

	events_clear(evts)
	ev_ptr<Event> = events_as_mut_ptr(evts)
	cap_u<u64> = events_get_capacity(evts)
	cap_i<i32> = cap_u.(i32)
	ep_fd<i32> = selector_ep(sel)
	n_events<i32> = libsys.epoll_wait(ep_fd, ev_ptr.(u64), cap_i, timeout_ms)
	if n_events == -1
		return libsys.last_error()
	events_set_count(evts, n_events.(u64))
	return libsys.Ok
}

// timeout_ms: -1 forever; else millis (mother Option<Duration>).
Selector::select(evts<Events>, timeout_ms_in<i32>) i32 {
	return selector_select_impl(this, evts, timeout_ms_in)
}

Selector::register(fd<i32>, t_bits<u64>, interest_bits<u8>) i32 {
	ev<Event> = new Event {
		flags: interests_to_epoll(interest_bits),
		token: t_bits
	}
	ret<i32> = libsys.epoll_ctl(selector_ep(this), EPOLL_CTL_ADD, fd, ev.(u64))
	if ret == -1
		return libsys.last_error()
	return libsys.Ok
}

Selector::register_readable(fd<i32>, t_bits<u64>) i32 {
	ev<Event> = new Event {
		flags: interests_to_epoll(1),
		token: t_bits
	}
	ret<i32> = libsys.epoll_ctl(selector_ep(this), EPOLL_CTL_ADD, fd, ev.(u64))
	if ret == -1
		return libsys.last_error()
	return libsys.Ok
}

Selector::reregister(fd<i32>, t_bits<u64>, interest_bits<u8>) i32 {
	ev<Event> = new Event {
		flags: interests_to_epoll(interest_bits),
		token: t_bits
	}
	ret<i32> = libsys.epoll_ctl(selector_ep(this), EPOLL_CTL_MOD, fd, ev.(u64))
	if ret == -1
		return libsys.last_error()
	return libsys.Ok
}

Selector::deregister(fd<i32>) i32 {
	ret<i32> = libsys.epoll_ctl(selector_ep(this), EPOLL_CTL_DEL, fd, 0)
	if ret == -1
		return libsys.last_error()
	return libsys.Ok
}

Selector::register_waker() i32 {
	already<i32> = selector_has_waker(this)
	selector_set_has_waker(this, 1)
	return already
}

Selector::id() u64 {
	return selector_id_bits(this)
}

Selector::as_raw_fd() i32 {
	return selector_ep(this)
}

Selector::drop() {
	libsys.close(selector_ep(this))
}

// Mother Interest::is_readable / is_writable, encoded as u8 bits.
fn interests_to_epoll(interest_bits<u8>) u32 {
	kind<u32> = EPOLLET
	if (interest_bits & 1) != 0
		kind = kind | EPOLLIN | EPOLLRDHUP
	if (interest_bits & 2) != 0
		kind = kind | EPOLLOUT
	return kind
}

fn event_token_bits(evt<Event>) u64 {
	return evt.token
}

fn event_is_readable(evt<Event>) i32 {
	return (evt.flags & EPOLLIN) != 0 || (evt.flags & EPOLLPRI) != 0
}

fn event_is_writable(evt<Event>) i32 {
	return (evt.flags & EPOLLOUT) != 0
}

fn event_is_error(evt<Event>) i32 {
	return (evt.flags & EPOLLERR) != 0
}

fn event_is_read_closed(evt<Event>) i32 {
	return (evt.flags & EPOLLHUP) != 0 || ((evt.flags & EPOLLIN) != 0 && (evt.flags & EPOLLRDHUP) != 0)
}

fn event_is_write_closed(evt<Event>) i32 {
	return (evt.flags & EPOLLHUP) != 0 || ((evt.flags & EPOLLOUT) != 0 && (evt.flags & EPOLLERR) != 0) || evt.flags == EPOLLERR
}

fn event_is_priority(evt<Event>) i32 {
	return (evt.flags & EPOLLPRI) != 0
}
