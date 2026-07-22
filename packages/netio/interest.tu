// Interest bitmask for register/reregister (mother netio::Interest).
// Field is `flags` (not `bits`) to avoid typeassert parse traps on `.bits`.
// Use decimal literals: Tu codegen currently evaluates 0b0001 / 0b0010 as 0,
// which registered sockets with EPOLLET-only and starved all IO readiness.

READABLE_BIT<u8> = 1
WRITABLE_BIT<u8> = 2

mem Interest {
	u8 flags
}

fn readable_interest() Interest {
	return new Interest { flags: READABLE_BIT }
}

fn writable_interest() Interest {
	return new Interest { flags: WRITABLE_BIT }
}

// Mother: Interest::add — OR the flag bits.
fn interest_merge(a<Interest>, b<Interest>) Interest {
	af<u8> = a.flags
	bf<u8> = b.flags
	return new Interest { flags: af | bf }
}

fn interest_as_u8(i<Interest>) u8 {
	return i.flags
}

// Mother: Interest::is_readable / is_writable.
fn interest_is_readable(i<Interest>) i32 {
	f<u8> = i.flags
	if (f & READABLE_BIT) != 0.(u8) {
		return 1
	}
	return 0
}

fn interest_is_writable(i<Interest>) i32 {
	f<u8> = i.flags
	if (f & WRITABLE_BIT) != 0.(u8) {
		return 1
	}
	return 0
}

fn readable_interest_bits() u64 {
	i<Interest> = readable_interest()
	return i.(u64)
}

fn writable_interest_bits() u64 {
	i<Interest> = writable_interest()
	return i.(u64)
}
