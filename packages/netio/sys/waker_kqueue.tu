// Darwin waker via EVFILT_USER (mio kqueue Waker). Same EventfdWaker name
// as Linux eventfd waker so netio.waker keeps working after install overlay.

use netio
use runtime
use sys as libsys

mem EventfdWaker {
	i32 kq_fd
	u64 tok_bits
	runtime.MutexInter* kq_mu // same lock as Selector kevent changelists
}

const EventfdWaker::new(selector_obj<Selector>, tok_bits_in<u64>) i32, EventfdWaker {
	err<i32> = selector_setup_waker_user(selector_obj, tok_bits_in)
	if err != libsys.Ok {
		return err, null
	}
	kq<i32> = selector_ep(selector_obj)
	return libsys.Ok, new EventfdWaker {
		kq_fd: kq,
		tok_bits: tok_bits_in,
		kq_mu: selector_obj.kq_mu
	}
}

EventfdWaker::wake() i32 {
	return eventfd_wake_fd(this)
}

EventfdWaker::reset() i32 {
	return eventfd_reset_fd(this)
}

fn eventfd_wake_fd(w<EventfdWaker>) i32 {
	// Rebuild a Selector shell so we can reuse kevent_register helpers.
	sel<Selector> = new Selector {
		id: 0,
		ep: w.kq_fd,
		has_waker: 1,
		kq_mu: w.kq_mu
	}
	return selector_wake_user(sel, w.tok_bits)
}

fn eventfd_reset_fd(w<EventfdWaker>) i32 {
	// EV_CLEAR on EVFILT_USER clears the trigger; no drain needed.
	return libsys.Ok
}
