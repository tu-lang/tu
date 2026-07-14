READABLE_BIT<u8> = 0b0001
WRITABLE_BIT<u8> = 0b0010

mem Interest {
	u8 bits
}

const Interest::readable() Interest {
	return new Interest { bits: READABLE_BIT }
}

// Package-level bridge for cross-subpackage callers (no Interest:: static call).
fn readable_interest() Interest {
	return Interest::readable()
}

// Heap bits of Interest::readable for packages that cannot resolve readable_interest().
fn readable_interest_bits() u64 {
	i<Interest> = Interest::readable()
	return i.(u64)
}

fn interest_from_bits(bits<u64>) Interest {
	return bits.(Interest)
}

const Interest::writable() Interest {
	return new Interest { bits: WRITABLE_BIT }
}

// Package-level bridge for cross-subpackage callers (no Interest:: static call).
fn writable_interest() Interest {
	return Interest::writable()
}

const Interest::add(other<Interest>) Interest {
	return new Interest { bits: this.bits | other.bits }
}

// Package-level merge for cross-subpackage callers.
fn interest_merge(a<Interest>, b<Interest>) Interest {
	return a.add(b)
}

Interest::is_readable() i32 {
	return (this.bits & READABLE_BIT) != 0
}

Interest::is_writable() i32 {
	return (this.bits & WRITABLE_BIT) != 0
}

// Cross-pkg bridges (caller holds Interest as typed value / bits).
fn interest_is_readable(i<Interest>) i32 {
	return i.is_readable()
}

fn interest_is_writable(i<Interest>) i32 {
	return i.is_writable()
}
