READABLE_BIT<u8> = 0b0001
WRITABLE_BIT<u8> = 0b0010

mem Interest {
	u8 bits
}

const Interest::readable() Interest {
	return new Interest { bits: READABLE_BIT }
}

const Interest::writable() Interest {
	return new Interest { bits: WRITABLE_BIT }
}

const Interest::add(other<Interest>) Interest {
	return new Interest { bits: this.bits | other.bits }
}

Interest::is_readable() i32 {
	return (this.bits & READABLE_BIT) != 0
}

Interest::is_writable() i32 {
	return (this.bits & WRITABLE_BIT) != 0
}
