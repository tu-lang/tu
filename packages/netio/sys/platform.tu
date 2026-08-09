use io
use net

// Platform hooks for sync TCP (connect finish, enrolled accept prep).
// Linux default: no-ops — mother returns Ok on EINPROGRESS; epoll async drives I/O.
// Darwin: install-darwin overlays platform/darwin/netio_platform.tu onto this file.

// Selector slot stored on IoSource.platform_slot at enroll; Linux keeps 0.
fn platform_enroll_selector_slot(sel_bits<u64>) u64 {
	return 0.(u64)
}

fn platform_on_detach_selector_slot() u64 {
	return 0.(u64)
}

// After non-blocking connect returns EINPROGRESS; Linux leaves async path unchanged.
fn platform_connect_finish(fd<i32>, addr<net.SocketAddr>) i32 {
	return Ok
}

// Sync accept on a listen fd enrolled on the reactor; Linux needs no prep.
fn platform_before_accept(selector_slot<u64>, listen_fd<i32>) {
}
