use fmt
use std
use string
Reader::read_u8(out<u8*>) { return this.read(out, U8) }
Reader::read_i8(out<i8*>) { return this.read(out, I8) }
Reader::read_u16(out<u16*>) { return this.read(out, U16) }
Reader::read_u32(out<u32*>) { return this.read(out, U32) }
Reader::read_u64(out<u64*>) { return this.read(out, U64) }

Reader::finish()
{
	if this.offset >= this.len {
    	return True
	}
  	return False
}

Reader::read(out<i8*>, count<i32>) {
    if this.offset + count > this.len {
		this.offset = this.len
		return False
    }
    if out != null
		std.memcpy(out, this.buffer + this.offset, count)
    this.offset += count
    return True
}
Reader::read_str(str<string.String>) {
    c<u8> = 0
    while True {
      	if this.read_u8(&c) == Null
        	return False
      	if c == 0
        	break
		str.putc(c)
    }
    return str
}

Reader::read_uleb128(out<u64*>) {
	value<u64> = 0
	shift<i32> = 0
	b<u8> = 0
	while True {
      	if this.read_u8(&b) == Null
        	return False
		u64b<u64> = b
      	value |= (u64b & 0x7F) << shift
      	if (b & 0x80) == 0
        	break
      	shift += 7
    }
    if out != null
      	*out = value
    return True
}

Reader::read_sleb128(out<i64*>) {
	value<i64> = 0
	shift<i32> = 0
    b<u8> = 0
    while True {
      	if this.read_u8(&b) == Null
        	return False
		u64b<u64> = b
      	value |= (u64b & 0x7F) << shift
      	shift += 7
      	if (b & 0x80) == 0
        	break
    }
    if (shift < 64 && (b & 0x40))
      	value |= 0 - (1 << shift)
    if out != null
      	*out = value
    return True
}

Reader::read_initial_length(out<u32*>) {
    if this.read_u32(out) == Null
      	return False
    return True
}

Reader::align(boundary<i32>) {
    extra<i32> = this.offset % boundary
    if extra != 0 {
      	pad<i32> = boundary - extra
      	return this.read(Null, pad)
    }
    return True
}


