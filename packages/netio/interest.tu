READABLE_BIT<u8> = 0b0001
WRITABLE_BIT<u8> = 0b0010

mem Interest {
	u8 bits
}

const Interest_readable() Interest {
	return new Interest { bits: READABLE_BIT }
}

const Interest_writable() Interest {
	return new Interest { bits: WRITABLE_BIT }
}

const Interest::add(other<Interest>) Interest {
	return new Interest { bits: this.bits | other.bits }
}

const Interest::is_readable() bool {
	return (this.bits & READABLE_BIT) != 0
}

const Interest::is_writable() bool {
	return (this.bits & WRITABLE_BIT) != 0
}
