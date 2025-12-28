mem U16 {
	u16 inner
}

const U16::is_le() i32 {
	x<u16> = 1
	x2<u16> = &x
	return *x2 == 1
}

const U16::from_be(x<u16>) u16 {
	if U16::is_le() {
        return (x >> 8) | (x << 8)
    }
    return x
}
