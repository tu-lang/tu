# Linux-style no-op finish — async path needs EINPROGRESS + readiness.
use io
use net

fn platform_enroll_selector_slot(sel_bits<u64>) u64 {
	return sel_bits
}

fn platform_on_detach_selector_slot() u64 {
	return 0.(u64)
}

fn platform_connect_finish(fd<i32>, addr<net.SocketAddr>) i32 {
	return Ok
}

fn platform_before_accept(selector_slot<u64>, listen_fd<i32>) {
}
