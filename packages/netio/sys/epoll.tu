// epoll Selector (mother: netio/src/sys/epoll.rs).
// Kernel epoll_event is packed 12 bytes (u32 events + u64 data at offset 4).
// Tu mem cannot express packed layout, so Events store a raw packed buffer
// and unpack on read; epoll_ctl packs into a 12-byte scratch.

use netio
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

// Linux x86_64 sizeof(struct epoll_event) with __attribute__((packed)).
KERNEL_EVENT_SIZE<u64> = 12

// Unpacked logical event used by netio callers (not the kernel layout).
mem Event {
	u32 flags
	u64 token
}

mem Events {
	u64  store_bits
	u64  count
	u64  capacity_val
}

const Events::with_capacity(capacity<u64>) Events {
	// noscan=1: epoll_wait writes kernel epoll_event bytes here. A scannable
	// buffer lets concurrent GC mark those bytes as pointers → heap corruption.
	ptr_bits<u64> = runtime.malloc(KERNEL_EVENT_SIZE * capacity, 1.(i8), 1.(i8))
	return new Events { store_bits: ptr_bits, count: 0, capacity_val: capacity }
}

fn events_clear(evts<Events>) {
	evts.count = 0
}

fn events_as_mut_ptr(evts<Events>) u64 {
	return evts.store_bits
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

// Read little-endian u32 at aligned address bits.
fn packed_read_u32(p_bits<u64>) u32 {
	out<u32> = 0
	dst<u8*> = null
	src<u8*> = null
	dst = &out
	src = p_bits
	std.memcpy(dst, src, 4)
	return out
}

// Read little-endian u64 at possibly unaligned address bits.
fn packed_read_u64(p_bits<u64>) u64 {
	out<u64> = 0
	dst<u8*> = null
	src<u8*> = null
	dst = &out
	src = p_bits
	std.memcpy(dst, src, 8)
	return out
}

fn packed_write_u32(p_bits<u64>, v<u32>) {
	dst<u8*> = null
	src<u8*> = null
	dst = p_bits
	src = &v
	std.memcpy(dst, src, 4)
}

fn packed_write_u64(p_bits<u64>, v<u64>) {
	dst<u8*> = null
	src<u8*> = null
	dst = p_bits
	src = &v
	std.memcpy(dst, src, 8)
}

// Pack (flags, token) into a 12-byte heap buffer; returns pointer bits for epoll_ctl.
fn pack_kernel_event(flags<u32>, token<u64>) u64 {
	// noscan: packed kernel layout, not a pointer graph for the marker.
	base_bits<u64> = runtime.malloc(KERNEL_EVENT_SIZE, 1.(i8), 1.(i8))
	packed_write_u32(base_bits, flags)
	packed_write_u64(base_bits + 4, token)
	return base_bits
}

fn events_get(evts<Events>, pos<u64>) Event {
	if pos >= evts.count
		return null
	base_bits<u64> = evts.store_bits + (pos * KERNEL_EVENT_SIZE)
	flags<u32> = packed_read_u32(base_bits)
	token<u64> = packed_read_u64(base_bits + 4)
	return new Event { flags: flags, token: token }
}

Events::clear() {
	events_clear(this)
}

Events::as_mut_ptr() u64 {
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

const Selector::new(_unused<i32>) i32, Selector {
	s<Selector> = selector_create()
	if s == null
		return libsys.last_error(), null
	return libsys.Ok, s
}

fn selector_create() Selector {
	raw<i32> = libsys.epoll_create1(EPOLL_CLOEXEC)
	// Raw syscall returns -errno (not libc -1); cvt maps EINTR/etc.
	cerr<i32>, ep_u<u64> = libsys.cvt(raw)
	if cerr != libsys.Ok
		return null
	ep<i32> = ep_u.(i32)
	sid<u64> = NEXT_SELECTOR_ID
	NEXT_SELECTOR_ID += 1
	return new Selector {
		id: sid,
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
	raw_bits<u64> = events_as_mut_ptr(evts)
	cap_u<u64> = events_get_capacity(evts)
	cap_i<i32> = cap_u.(i32)
	ep_fd<i32> = selector_ep(sel)
	// Raw syscall: success >= 0, error = -errno (EINTR=-4). Checking == -1
	// missed EINTR and stored -4 as Events.count → iter ran past the buffer
	// (token garbage / SEGV) or dropped readiness (Recv-Q hang).
	n_raw<i32> = libsys.epoll_wait(ep_fd, raw_bits, cap_i, timeout_ms)
	cerr<i32>, n_u<u64> = libsys.cvt(n_raw)
	if cerr != libsys.Ok
		return cerr
	events_set_count(evts, n_u)
	return libsys.Ok
}

Selector::select(evts<Events>, timeout_ms_in<i32>) i32 {
	return selector_select_impl(this, evts, timeout_ms_in)
}

Selector::register(fd<i32>, t_bits<u64>, interest_bits<u8>) i32 {
	return selector_add_fd(this, fd, t_bits, interest_bits)
}

Selector::register_readable(fd<i32>, t_bits<u64>) i32 {
	return selector_add_fd(this, fd, t_bits, 1)
}

Selector::reregister(fd<i32>, t_bits<u64>, interest_bits<u8>) i32 {
	return selector_mod_fd(this, fd, t_bits, interest_bits)
}

Selector::deregister(fd<i32>) i32 {
	return selector_del_fd(this, fd)
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

fn selector_from_bits(bits<u64>) Selector {
	return bits.(Selector)
}
fn selector_to_bits(sel<Selector>) u64 {
	return sel.(u64)
}
fn selector_select(sel<Selector>, evts<Events>, timeout_ms<i32>) i32 {
	return selector_select_impl(sel, evts, timeout_ms)
}

// Package bridges — callers must not write `sel.register` / `.deregister`
// (type-assert traps). Bodies inlined; do not call Selector::register by name.
fn selector_add_fd(sel<Selector>, fd<i32>, t_bits<u64>, interest_bits<u8>) i32 {
	ev_bits<u64> = pack_kernel_event(interests_to_epoll(interest_bits), t_bits)
	ret<i32> = libsys.epoll_ctl(selector_ep(sel), EPOLL_CTL_ADD, fd, ev_bits)
	cerr<i32> = libsys.cvt(ret)
	if cerr != libsys.Ok
		return cerr
	return libsys.Ok
}
fn selector_mod_fd(sel<Selector>, fd<i32>, t_bits<u64>, interest_bits<u8>) i32 {
	ev_bits<u64> = pack_kernel_event(interests_to_epoll(interest_bits), t_bits)
	ret<i32> = libsys.epoll_ctl(selector_ep(sel), EPOLL_CTL_MOD, fd, ev_bits)
	cerr<i32> = libsys.cvt(ret)
	if cerr != libsys.Ok
		return cerr
	return libsys.Ok
}
fn selector_del_fd(sel<Selector>, fd<i32>) i32 {
	ret<i32> = libsys.epoll_ctl(selector_ep(sel), EPOLL_CTL_DEL, fd, 0)
	cerr<i32> = libsys.cvt(ret)
	if cerr != libsys.Ok
		return cerr
	return libsys.Ok
}

fn selector_register_waker_bit(sel<Selector>) i32 {
	already<i32> = selector_has_waker(sel)
	selector_set_has_waker(sel, 1)
	return already
}
fn selector_try_clone_bits(sel<Selector>) i32, u64 {
	err<i32>, cloned<Selector> = sel.try_clone()
	zero<u64> = 0
	ok_code<i32> = 1
	if err != ok_code return err, zero
	return err, selector_to_bits(cloned)
}
