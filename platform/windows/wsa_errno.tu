# WSA → Linux-style negative errno map (RFC-107 P1).
# Installed as runtime/wsa_errno.tu → symbol runtime_win_wsa_errno_neg.
# Asm trampoline win_wsa_errno_neg pushes the arg (Tu stack ABI) then calls this.

# Winsock error codes (subset used by syscall/windows).
WSAEWOULDBLOCK<i32> = 10035
WSAEINPROGRESS<i32> = 10036
WSAEALREADY<i32> = 10037
WSAEADDRINUSE<i32> = 10048
WSAECONNRESET<i32> = 10054
WSAECONNABORTED<i32> = 10053
WSAECONNREFUSED<i32> = 10061
WSAETIMEDOUT<i32> = 10060
WSAEINVAL<i32> = 10022
WSAEFAULT<i32> = 10014
WSAEMFILE<i32> = 10024
WSAEMSGSIZE<i32> = 10040
WSAENOTCONN<i32> = 10058

# Map positive WSA error to Linux -errno.
fn win_wsa_errno_neg(code<i32>) i64 {
	if code == WSAEWOULDBLOCK {
		return -11.(i64)
	}
	if code == WSAEINPROGRESS {
		return -115.(i64)
	}
	if code == WSAEALREADY {
		return -114.(i64)
	}
	if code == WSAEADDRINUSE {
		return -98.(i64)
	}
	if code == WSAECONNRESET {
		return -104.(i64)
	}
	if code == WSAECONNABORTED {
		return -103.(i64)
	}
	if code == WSAECONNREFUSED {
		return -111.(i64)
	}
	if code == WSAETIMEDOUT {
		return -110.(i64)
	}
	if code == WSAEINVAL {
		return -22.(i64)
	}
	if code == WSAEFAULT {
		return -14.(i64)
	}
	if code == WSAEMFILE {
		return -24.(i64)
	}
	if code == WSAEMSGSIZE {
		return -90.(i64)
	}
	if code == WSAENOTCONN {
		return -108.(i64)
	}
	neg<i64> = 0.(i64) - code.(i64)
	return neg
}
