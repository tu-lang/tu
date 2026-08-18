# Linux AF_INET6 sockaddr rewrite + eventfd loopback fill (RFC-107 P1).
# Avoids peff-sensitive byte stores in framed sys_* (call via SysV trampoline).

WIN_AF_INET6_LINUX<i8> = 10
WIN_AF_INET6_WIN<i8> = 23

# If sa_family is Linux AF_INET6, copy to dst and rewrite to Windows 23.
# Returns dst bits when rewritten, otherwise src (or 0 if src is null).
fn win_sockaddr_win_copy_tu(src<u64>, len<i64>, dst<u64>) u64 {
	if src == 0.(u64) {
		return 0.(u64)
	}
	if dst == 0.(u64) {
		return src
	}
	p<i8*> = src
	fam<i8> = p[0]
	if fam != WIN_AF_INET6_LINUX {
		return src
	}
	n<i32> = 0
	if len > 0.(i64) {
		n = len.(i32)
	}
	if n > 128 {
		n = 128
	}
	d<i8*> = dst
	i<i32> = 0
	while i < n {
		d[i] = p[i]
		i = i + 1
	}
	d[0] = WIN_AF_INET6_WIN
	if n > 1 {
		d[1] = 0.(i8)
	}
	return dst
}

# After Winsock fills a sockaddr, map Windows AF_INET6 (23) back to Linux 10.
fn win_sockaddr_to_linux_tu(addr<u64>) {
	if addr == 0.(u64) {
		return
	}
	p<i8*> = addr
	if p[0] != WIN_AF_INET6_WIN {
		return
	}
	p[0] = WIN_AF_INET6_LINUX
	p[1] = 0.(i8)
}

# Fill sockaddr_in 127.0.0.1:0 (16 bytes) for the UDP eventfd waker.
fn win_eventfd_loopback_tu(dst<u64>) {
	if dst == 0.(u64) {
		return
	}
	p<i8*> = dst
	i<i32> = 0
	while i < 16 {
		p[i] = 0.(i8)
		i = i + 1
	}
	p[0] = 2.(i8)
	p[4] = 127.(i8)
	p[7] = 1.(i8)
}
