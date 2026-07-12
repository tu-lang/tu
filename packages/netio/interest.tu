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
