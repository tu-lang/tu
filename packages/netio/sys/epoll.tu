use netio
use io
use runtime
use std
use sys as libsys

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

mem Event {
	u32 events
	u64 token
}

mem Events {
	Event* inner
	u64 len
	u64 cap
}

const Events::with_capacity(capacity<u64>) Events {
	ptr<u64> = std.malloc(sizeof(Event) * capacity)
	return new Events { inner: ptr.(Event), len: 0, cap: capacity }
}

Events::clear() {
	this.len = 0
}

Events::as_mut_ptr() Event {
	return this.inner
}

Events::capacity() u64 {
	return this.cap
}

Events::set_len(n<u64>) {
	this.len = n
}

Events::len() u64 {
	return this.len
}

Events::get(pos<u64>) Event {
	if pos >= this.len
		return null
	return this.inner + pos
}

mem Selector {
	u64 id
	i32 ep
	i32 has_waker
}

const Selector::new() i32, Selector {
	ep<i32> = sys_epoll_create1(EPOLL_CLOEXEC)
	if ep == -1
		return libsys.last_error(), null
	id<u64> = NEXT_SELECTOR_ID
	NEXT_SELECTOR_ID += 1
	return Ok, new Selector {
		id: id,
		ep: ep,
		has_waker: 0
	}
}

Selector::try_clone() i32, Selector {
	err<i32>, ep<i32> = libsys.cvt(sys_fcntl(this.ep, libsys.F_DUPFD_CLOEXEC, LOWEST_FD))
	if err != Ok
		return err, null
	return Ok, new Selector {
		id: this.id,
		ep: ep,
		has_waker: this.has_waker
	}
}

Selector::select(events<Events>, timeout<libsys.Duration>) i32 {
	timeout_ms<i32> = -1
	if timeout != null {
		ms<u64> = timeout.as_millis()
		if ms > runtime.I32_MAX
			timeout_ms = runtime.I32_MAX
		else
			timeout_ms = ms
	}

	events.clear()
	n_events<i32> = sys_epoll_wait(this.ep, events.as_mut_ptr(), events.capacity(), timeout_ms)
	if n_events == -1
		return libsys.last_error()
	events.set_len(n_events)
	return Ok
}

Selector::register(fd<i32>, t<netio.Token>, interests<netio.Interest>) i32 {
	ev<Event> = new Event {
		events: interests_to_epoll(interests),
		token: t.as_u64()
	}
	ret<i32> = sys_epoll_ctl(this.ep, EPOLL_CTL_ADD, fd, ev)
	if ret == -1
		return libsys.last_error()
	return Ok
}

Selector::reregister(fd<i32>, t<netio.Token>, interests<netio.Interest>) i32 {
	ev<Event> = new Event {
		events: interests_to_epoll(interests),
		token: t.as_u64()
	}
	ret<i32> = sys_epoll_ctl(this.ep, EPOLL_CTL_MOD, fd, ev)
	if ret == -1
		return libsys.last_error()
	return Ok
}

Selector::deregister(fd<i32>) i32 {
	ret<i32> = sys_epoll_ctl(this.ep, EPOLL_CTL_DEL, fd, null)
	if ret == -1
		return libsys.last_error()
	return Ok
}

Selector::register_waker() i32 {
	already<i32> = this.has_waker
	this.has_waker = 1
	return already
}

Selector::id() u64 {
	return this.id
}

Selector::as_raw_fd() i32 {
	return this.ep
}

Selector::drop() {
	sys_close(this.ep)
}

fn interests_to_epoll(interests<netio.Interest>) u32 {
	kind<u32> = EPOLLET
	if interests.is_readable()
		kind = kind | EPOLLIN | EPOLLRDHUP
	if interests.is_writable()
		kind = kind | EPOLLOUT
	return kind
}

fn event_token_bits(evt<Event>) u64 {
	return evt.token
}

fn event_is_readable(evt<Event>) i32 {
	return (evt.events & EPOLLIN) != 0 || (evt.events & EPOLLPRI) != 0
}

fn event_is_writable(evt<Event>) i32 {
	return (evt.events & EPOLLOUT) != 0
}

fn event_is_error(evt<Event>) i32 {
	return (evt.events & EPOLLERR) != 0
}

fn event_is_read_closed(evt<Event>) i32 {
	return (evt.events & EPOLLHUP) != 0 || ((evt.events & EPOLLIN) != 0 && (evt.events & EPOLLRDHUP) != 0)
}

fn event_is_write_closed(evt<Event>) i32 {
	return (evt.events & EPOLLHUP) != 0 || ((evt.events & EPOLLOUT) != 0 && (evt.events & EPOLLERR) != 0) || evt.events == EPOLLERR
}

fn event_is_priority(evt<Event>) i32 {
	return (evt.events & EPOLLPRI) != 0
}
