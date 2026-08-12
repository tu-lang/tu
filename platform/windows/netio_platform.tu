# Windows netio platform hooks (software epoll via WSAPoll in syscall).
# Installed over packages/netio/sys/platform.tu by install-windows.cmd.

use io
use net
use sys as libsys

F_SETFL<i32> = 4
O_NONBLOCK_LINUX<i32> = 2048
# SOL_SOCKET / SO_ERROR: defined in net.tu (same package). Do not redefine (LNK2005).

fn platform_enroll_selector_slot(sel_bits<u64>) u64 {
	return sel_bits
}

fn platform_on_detach_selector_slot() u64 {
	return 0.(u64)
}

// Poll SO_ERROR until nonblocking connect completes or fails.
fn platform_connect_finish(fd<i32>, addr<net.SocketAddr>) i32 {
	optlen<i32> = 4
	optval<i32> = 0
	vp<i32*> = &optval
	opt_bits<u64> = vp.(u64)
	i<i32> = 0
	while i < 500 {
		gs<i32> = libsys.getsockopt(fd, SOL_SOCKET, SO_ERROR, opt_bits, &optlen)
		if gs == 0 {
			if optval == 0 {
				return libsys.Ok
			}
			neg<i32> = 0 - optval
			cerr<i32> = libsys.cvt(neg)
			return cerr
		}
		i += 1
	}
	return io.OS_EINPROGRESS
}

fn platform_before_accept(selector_slot<u64>, listen_fd<i32>) {
	// Linux default is no-op; async IoDriver owns epoll/WSAPoll. A second
	// synchronous poll here does not update ScheduledIo readiness, so
	// accept().await can park forever while connections sit in the backlog
	// (ct_spawn_fair / mt_conn_flood / mt_stress_spawn on Windows).
}
