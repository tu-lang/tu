// kqueue Selector for Darwin (mio-compatible). Same public surface as epoll.tu:
// Selector / Events / Event with EPOLL* flag bits after select() conversion.
// Installed over copkg/.../epoll.tu on Darwin so callers keep using netio.sys.

use netio
use runtime
use std
use sys as libsys
use io

LOWEST_FD<i32> = 3
F_SETFD<i32> = 2
FD_CLOEXEC<i32> = 1

// Logical readiness bits — match Linux epoll Event consumers.
EPOLLIN<u32> = 0x001
EPOLLPRI<u32> = 0x002
EPOLLOUT<u32> = 0x004
EPOLLERR<u32> = 0x008
EPOLLHUP<u32> = 0x010
EPOLLRDHUP<u32> = 0x2000
EPOLLET<u32> = 0x80000000

// Darwin struct kevent is 32 bytes; Events still stores 12-byte packed
// (flags u32 + token u64) after select converts each kevent.
KEVENT_SIZE<u64> = 32
KERNEL_EVENT_SIZE<u64> = 12

EVFILT_READ<i16> = -1
EVFILT_WRITE<i16> = -2
EVFILT_USER<i16> = -10

EV_ADD<u16> = 0x0001
EV_DELETE<u16> = 0x0002
EV_CLEAR<u16> = 0x0020
EV_RECEIPT<u16> = 0x0040
EV_ERROR<u16> = 0x4000
EV_EOF<u16> = 0x8000
NOTE_TRIGGER<u32> = 0x01000000

EPIPE_I64<i64> = 32
ENOENT_I64<i64> = 2

NEXT_SELECTOR_ID<u64> = 1

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

fn packed_read_u16(p_bits<u64>) u16 {
	out<u16> = 0
	dst<u8*> = null
	src<u8*> = null
	dst = &out
	src = p_bits
	std.memcpy(dst, src, 2)
	return out
}

fn packed_read_u32(p_bits<u64>) u32 {
	out<u32> = 0
	dst<u8*> = null
	src<u8*> = null
	dst = &out
	src = p_bits
	std.memcpy(dst, src, 4)
	return out
}

fn packed_read_u64(p_bits<u64>) u64 {
	out<u64> = 0
	dst<u8*> = null
	src<u8*> = null
	dst = &out
	src = p_bits
	std.memcpy(dst, src, 8)
	return out
}

fn packed_write_u16(p_bits<u64>, v<u16>) {
	dst<u8*> = null
	src<u8*> = null
	dst = p_bits
	src = &v
	std.memcpy(dst, src, 2)
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

fn pack_kernel_event(flags<u32>, token<u64>) u64 {
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
	runtime.MutexInter* kq_mu // serializes kevent changelists (not wait)
}

const Selector::new(_unused<i32>) i32, Selector {
	s<Selector> = selector_create()
	if s == null
		return libsys.last_error(), null
	return libsys.Ok, s
}

fn selector_create() Selector {
	raw<i32> = libsys.kqueue()
	cerr<i32>, kq_u<u64> = libsys.cvt(raw)
	if cerr != libsys.Ok
		return null
	kq<i32> = kq_u.(i32)
	fc_raw<i32> = libsys.fcntl(kq, F_SETFD, FD_CLOEXEC)
	fc_err<i32> = libsys.cvt(fc_raw)
	if fc_err != libsys.Ok {
		libsys.close(kq)
		return null
	}
	sid<u64> = NEXT_SELECTOR_ID
	NEXT_SELECTOR_ID += 1
	mu<runtime.MutexInter> = new runtime.MutexInter
	return new Selector {
		id: sid,
		ep: kq,
		has_waker: 0,
		kq_mu: mu
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
		has_waker: selector_has_waker(this),
		kq_mu: this.kq_mu
	}
}

// Write one Darwin kevent (32 bytes) at p_bits.
fn kevent_write(p_bits<u64>, ident<u64>, filter<i16>, flags<u16>, fflags<u32>, data_v<i64>, udata<u64>) {
	std.memset(p_bits, 0, KEVENT_SIZE)
	packed_write_u64(p_bits, ident)
	filt_u<u16> = filter.(u16)
	packed_write_u16(p_bits + 8, filt_u)
	packed_write_u16(p_bits + 10, flags)
	packed_write_u32(p_bits + 12, fflags)
	data_u<u64> = data_v.(u64)
	packed_write_u64(p_bits + 16, data_u)
	packed_write_u64(p_bits + 24, udata)
}

fn kevent_read_filter(p_bits<u64>) i16 {
	u<u16> = packed_read_u16(p_bits + 8)
	return u.(i16)
}

fn kevent_read_flags(p_bits<u64>) u16 {
	return packed_read_u16(p_bits + 10)
}

fn kevent_read_data(p_bits<u64>) i64 {
	u<u64> = packed_read_u64(p_bits + 16)
	return u.(i64)
}

fn kevent_read_udata(p_bits<u64>) u64 {
	return packed_read_u64(p_bits + 24)
}

fn kevent_to_epoll_flags(filter<i16>, flags<u16>) u32 {
	out<u32> = 0
	if filter == EVFILT_READ || filter == EVFILT_USER {
		out = out | EPOLLIN
	}
	if filter == EVFILT_WRITE {
		out = out | EPOLLOUT
	}
	if (flags & EV_ERROR) != 0.(u16) {
		out = out | EPOLLERR
	}
	if (flags & EV_EOF) != 0.(u16) {
		out = out | EPOLLHUP
		if filter == EVFILT_READ {
			out = out | EPOLLRDHUP
		}
	}
	return out
}

fn selector_kq_lock(sel<Selector>) {
	if sel == null {
		return
	}
	mu<runtime.MutexInter> = sel.kq_mu
	if mu == null {
		return
	}
	mu.lock()
}

fn selector_kq_unlock(sel<Selector>) {
	if sel == null {
		return
	}
	mu<runtime.MutexInter> = sel.kq_mu
	if mu == null {
		return
	}
	mu.unlock()
}

// Apply changelist under Selector lock. Concurrent EV_ADD from MT workers
// without this races Darwin kevent and drops WRITE/READ interests.
fn kevent_register_locked(sel<Selector>, changes_bits<u64>, nchanges<i32>) i32 {
	selector_kq_lock(sel)
	err<i32> = kevent_register(selector_ep(sel), changes_bits, nchanges)
	selector_kq_unlock(sel)
	return err
}

// Apply changelist only (nevents=0). Never pass the changelist as the
// eventlist: a concurrent select wait would lose those events (Darwin
// delivers pending fd readiness into whichever kevent asks for them).
// EV_RECEIPT receipts are not collected; ENOENT/EPIPE on EV_DELETE are
// ignored via errno, matching typical kqueue register.
fn kevent_register(kq<i32>, changes_bits<u64>, nchanges<i32>) i32 {
	null_ev<u64> = 0
	zero_n<i32> = 0
	zero_ts<u64> = 0
	n_raw<i32> = libsys.kevent(kq, changes_bits, nchanges, null_ev, zero_n, zero_ts)
	cerr<i32> = libsys.cvt(n_raw)
	if cerr != libsys.Ok {
		if cerr == io.Interrupted {
			return libsys.Ok
		}
		if cerr == io.NotFound {
			return libsys.Ok
		}
		return cerr
	}
	return libsys.Ok
}

fn interests_base_flags(interest_bits<u8>) u16 {
	// Always level-triggered on Darwin kqueue. EV_CLEAR (edge) loses listen
	// backlog readiness when the edge fires before a waiter is armed or when
	// dispatch drops the event — spawn-before-accept then hangs forever.
	// Do not set EV_RECEIPT: receipts are harvested by a concurrent wait
	// kevent and look like spurious EV_ERROR (connect WRITABLE stolen).
	fl<u16> = EV_ADD
	return fl
}

fn selector_add_fd(sel<Selector>, fd<i32>, t_bits<u64>, interest_bits<u8>) i32 {
	fl<u16> = interests_base_flags(interest_bits)
	n<i32> = 0
	buf<u64> = runtime.malloc(KEVENT_SIZE * 2.(u64), 1.(i8), 1.(i8))
	ident<u64> = 0
	ident = fd
	if (interest_bits & 2) != 0.(u8) {
		kevent_write(buf + (n.(u64) * KEVENT_SIZE), ident, EVFILT_WRITE, fl, 0, 0, t_bits)
		n = n + 1
	}
	if (interest_bits & 1) != 0.(u8) {
		kevent_write(buf + (n.(u64) * KEVENT_SIZE), ident, EVFILT_READ, fl, 0, 0, t_bits)
		n = n + 1
	}
	// Empty interest must not silently succeed — that parks forever on accept.
	if n == 0 {
		return io.InvalidInput
	}
	return kevent_register_locked(sel, buf, n)
}

fn selector_mod_fd(sel<Selector>, fd<i32>, t_bits<u64>, interest_bits<u8>) i32 {
	// Level-triggered mod (no EV_CLEAR / EV_RECEIPT) — see interests_base_flags.
	write_fl<u16> = EV_DELETE
	read_fl<u16> = EV_DELETE
	if (interest_bits & 2) != 0.(u8) {
		write_fl = EV_ADD
	}
	if (interest_bits & 1) != 0.(u8) {
		read_fl = EV_ADD
	}
	buf<u64> = runtime.malloc(KEVENT_SIZE * 2.(u64), 1.(i8), 1.(i8))
	ident<u64> = 0
	ident = fd
	kevent_write(buf, ident, EVFILT_WRITE, write_fl, 0, 0, t_bits)
	kevent_write(buf + KEVENT_SIZE, ident, EVFILT_READ, read_fl, 0, 0, t_bits)
	return kevent_register_locked(sel, buf, 2)
}

fn selector_del_fd(sel<Selector>, fd<i32>) i32 {
	fl<u16> = EV_DELETE
	buf<u64> = runtime.malloc(KEVENT_SIZE * 2.(u64), 1.(i8), 1.(i8))
	ident<u64> = 0
	ident = fd
	kevent_write(buf, ident, EVFILT_WRITE, fl, 0, 0, 0)
	kevent_write(buf + KEVENT_SIZE, ident, EVFILT_READ, fl, 0, 0, 0)
	return kevent_register_locked(sel, buf, 2)
}

// EVFILT_USER waker registration (mio Selector::setup_waker).
fn selector_setup_waker_user(sel<Selector>, tok_bits<u64>) i32 {
	fl<u16> = EV_ADD | EV_CLEAR
	buf<u64> = runtime.malloc(KEVENT_SIZE, 1.(i8), 1.(i8))
	kevent_write(buf, 0, EVFILT_USER, fl, 0, 0, tok_bits)
	return kevent_register_locked(sel, buf, 1)
}

// Trigger EVFILT_USER (mio Selector::wake).
fn selector_wake_user(sel<Selector>, tok_bits<u64>) i32 {
	fl<u16> = EV_ADD
	buf<u64> = runtime.malloc(KEVENT_SIZE, 1.(i8), 1.(i8))
	kevent_write(buf, 0, EVFILT_USER, fl, NOTE_TRIGGER, 0, tok_bits)
	return kevent_register_locked(sel, buf, 1)
}

fn selector_select_impl(sel<Selector>, evts<Events>, timeout_ms_in<i32>) i32 {
	timeout_ms<i32> = timeout_ms_in
	events_clear(evts)
	cap_u<u64> = events_get_capacity(evts)
	cap_i<i32> = cap_u.(i32)
	raw_bits<u64> = runtime.malloc(KEVENT_SIZE * cap_u, 1.(i8), 1.(i8))
	timeout_ptr<u64> = 0
	if timeout_ms >= 0 {
		ts_bits<u64> = runtime.malloc(16.(u64), 1.(i8), 1.(i8))
		sec<i64> = 0
		nsec<i64> = 0
		if timeout_ms > 0 {
			sec = (timeout_ms / 1000).(i64)
			nsec = ((timeout_ms % 1000) * 1000000).(i64)
		}
		sec_u<u64> = 0
		nsec_u<u64> = 0
		sec_u = sec
		nsec_u = nsec
		packed_write_u64(ts_bits, sec_u)
		packed_write_u64(ts_bits + 8, nsec_u)
		timeout_ptr = ts_bits
	}
	kq_fd<i32> = selector_ep(sel)
	// Native externs: integer literals are boxed by codegen — use typed zeros.
	null_changes<u64> = 0
	zero_n<i32> = 0
	n_raw<i32> = libsys.kevent(kq_fd, null_changes, zero_n, raw_bits, cap_i, timeout_ptr)
	cerr<i32>, n_u<u64> = libsys.cvt(n_raw)
	if cerr != libsys.Ok
		return cerr
	out_i<u64> = 0
	i<u64> = 0
	while i < n_u {
		base<u64> = raw_bits + (i * KEVENT_SIZE)
		fl_k<u16> = kevent_read_flags(base)
		filt<i16> = kevent_read_filter(base)
		// Keep EV_ERROR in the wait list. Darwin reports non-blocking
		// connect completion as EVFILT_WRITE|EV_ERROR (errno in data).
		// Dropping those left poll_write_ready pending forever.
		tok<u64> = kevent_read_udata(base)
		ep_fl<u32> = kevent_to_epoll_flags(filt, fl_k)
		dst<u64> = events_as_mut_ptr(evts) + (out_i * KERNEL_EVENT_SIZE)
		packed_write_u32(dst, ep_fl)
		packed_write_u64(dst + 4, tok)
		out_i = out_i + 1
		i = i + 1
	}
	events_set_count(evts, out_i)
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
