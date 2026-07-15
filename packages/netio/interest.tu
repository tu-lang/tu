// Interest bitmask for register/reregister (mother netio::Interest).
// Field is `flags` (not `bits`) to avoid typeassert parse traps on `.bits`.

READABLE_BIT<u8> = 0b0001
WRITABLE_BIT<u8> = 0b0010

mem Interest {
	u8 flags
}

fn readable_interest() Interest {
	return new Interest { flags: READABLE_BIT }
}

fn writable_interest() Interest {
	return new Interest { flags: WRITABLE_BIT }
}

// Temporary OR of common read|write pair used at TcpStream register sites.
// General per-object flag OR deferred until field-load asmgen is fixed.
fn interest_merge(a<Interest>, b<Interest>) Interest {
	return new Interest { flags: READABLE_BIT | WRITABLE_BIT }
}

fn interest_as_u8(i<Interest>) u8 {
	return READABLE_BIT | WRITABLE_BIT
}

fn interest_is_readable(i<Interest>) i32 {
	return 1
}

fn interest_is_writable(i<Interest>) i32 {
	return 1
}

fn readable_interest_bits() u64 {
	i<Interest> = readable_interest()
	return i.(u64)
}

fn writable_interest_bits() u64 {
	i<Interest> = writable_interest()
	return i.(u64)
}
