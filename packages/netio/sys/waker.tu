// eventfd-based thread waker. Mother: netio/src/sys/waker.rs eventfd::Waker

use netio
use sys as libsys

WAKE_WOULD_BLOCK<i32> = 16908302

mem EventfdWaker {
	i32 fd_num
}

const EventfdWaker::new(selector_obj<Selector>, tok_bits<u64>) i32, EventfdWaker {
	raw<i32> = libsys.eventfd(0, 0x80000 | 0x800)
	err<i32>, fd_u<u64> = libsys.cvt(raw)
	if err != libsys.Ok {
		return err, null
	}
	fd<i32> = fd_u.(i32)

	err = selector_obj.register_readable(fd, tok_bits)
	if err != libsys.Ok {
		libsys.close(fd)
		return err, null
	}

	return libsys.Ok, new EventfdWaker { fd_num: fd }
}

EventfdWaker::wake() i32 {
	return eventfd_wake_fd(this)
}

EventfdWaker::reset() i32 {
	return eventfd_reset_fd(this)
}

fn eventfd_wake_fd(w<EventfdWaker>) i32 {
	one<u64> = 1
	n<u64> = 8
	err<i32>, junk<u64> = libsys.cvt(libsys.write(w.fd_num, &one, n))
	if err == WAKE_WOULD_BLOCK {
		rerr<i32> = eventfd_reset_fd(w)
		if rerr != libsys.Ok {
			return rerr
		}
		return eventfd_wake_fd(w)
	}
	return err
}

fn eventfd_reset_fd(w<EventfdWaker>) i32 {
	tmp<u64> = 0
	n<u64> = 8
	err<i32>, junk<u64> = libsys.cvt(libsys.read(w.fd_num, &tmp, n))
	if err == WAKE_WOULD_BLOCK {
		return libsys.Ok
	}
	return err
}
