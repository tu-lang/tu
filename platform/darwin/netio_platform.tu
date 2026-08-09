use io
use net
use runtime
use sys as libsys

// Darwin netio platform hooks (kqueue LT + ulock futex live elsewhere).
// Installed over packages/netio/sys/platform.tu by make install-darwin.

F_GETFL<i32> = 3
F_SETFL<i32> = 4
O_NONBLOCK_LINUX<i32> = 2048

SYNC_ACCEPT_WAIT_MS<i32> = 200

fn platform_enroll_selector_slot(sel_bits<u64>) u64 {
	return sel_bits
}

fn platform_on_detach_selector_slot() u64 {
	return 0.(u64)
}

// Block until EINPROGRESS connect completes (sync netio callers without a driver).
fn platform_connect_finish(fd<i32>, addr<net.SocketAddr>) i32 {
	raw_fl<i32> = libsys.fcntl(fd, F_GETFL, 0)
	ferr<i32>, fl_bits<u64> = libsys.cvt(raw_fl)
	if ferr != libsys.Ok {
		return ferr
	}
	saved<i32> = fl_bits.(i32)
	block_fl<i32> = saved & (~O_NONBLOCK_LINUX)
	serr<i32>, junk_s<u64> = libsys.cvt(libsys.fcntl(fd, F_SETFL, block_fl))
	if serr != libsys.Ok {
		return serr
	}
	ptr_bits<u64>, raw_len<i32> = socket_addr(addr)
	cerr_raw<i32> = libsys.connect(fd, ptr_bits, raw_len)
	rerr<i32>, junk_c<u64> = libsys.cvt(cerr_raw)
	rstor<i32>, junk_r<u64> = libsys.cvt(libsys.fcntl(fd, F_SETFL, saved))
	if rstor != libsys.Ok {
		return rstor
	}
	if rerr == libsys.Ok {
		return libsys.Ok
	}
	optlen<i32> = 4
	optval<i32> = 0
	vp<i32*> = &optval
	opt_bits<u64> = vp.(u64)
	gs<i32> = libsys.getsockopt(fd, SOL_SOCKET, SO_ERROR, opt_bits, &optlen)
	if gs == 0 && optval == 0 {
		return libsys.Ok
	}
	return rerr
}

// Harvest kqueue readiness before accept4 when the listen fd is enrolled (LT).
fn platform_before_accept(selector_slot<u64>, listen_fd<i32>) {
	if selector_slot == 0.(u64) {
		return
	}
	sel<Selector> = null
	sel = selector_slot
	evts<Events> = Events::with_capacity(8.(u64))
	selector_select_impl(sel, evts, SYNC_ACCEPT_WAIT_MS)
}
