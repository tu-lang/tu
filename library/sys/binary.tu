mem U16 {
	u16 bits
}

const U16::is_le() i32 {
	x<u16> = 1
	x2<u16*> = &x
	return *x2 == 1
}

const U16::from_be(x<u16>) u16 {
	if U16::is_le() {
        return (x >> 8) | (x << 8)
    }
    return x
}

// Host-endian u16 -> big-endian wire order (Rust u16::to_be).
const U16::to_be(x<u16>) u16 {
	if U16::is_le() {
        return (x >> 8) | (x << 8)
    }
    return x
}

// Package bridges for cross-pkg callers (cannot write U16::to_be outside sys).
fn u16_to_be(x<u16>) u16 {
    return U16::to_be(x)
}

fn u16_from_be(x<u16>) u16 {
    return U16::from_be(x)
}
