use runtime

mem Cursor {
	Buf* inner
	u64 pos
}

const Cursor::new(inner<Buf>) Cursor {
	return new Cursor { pos: 0, inner: inner }
}

Cursor::into_inner() Buf {
	return this.inner
}

const Cursor::get_ref() Buf {
	return this.inner
}

Cursor::get_mut() Buf {
	return this.inner
}

const Cursor::position() u64 {
	return this.pos
}

Cursor::set_position(pos<u64>) {
	this.pos = pos
}

Cursor::remaining_slice() Buf {
	len<u64> = min_u64(this.pos, this.inner.len())
	return new Buf {
		inner: this.inner.inner + len,
		len: this.inner.len() - len
	}
}

Cursor::is_empty() bool {
	return this.pos >= this.inner.len()
}

Cursor::clone() Cursor {
	return new Cursor { inner: this.inner.dup(), pos: this.pos }
}

Cursor::clone_from(other<Cursor>) {
	this.inner = other.inner.dup()
	this.pos = other.pos
}

fn checked_add_signed_u64(base_pos<u64>, offset<i64>) i32, u64 {
	max_u64<u64> = runtime.U64_MAX
	if offset >= 0 {
		delta<u64> = offset
		if delta > (max_u64 - base_pos)
			return InvalidInputSeekNegativeOverflowing, 0
		return Ok, base_pos + delta
	}

	// Avoid overflowing when offset is i64 min.
	delta_minus_1<i64> = 0 - (offset + 1)
	delta<u64> = delta_minus_1 + 1
	if base_pos < delta
		return InvalidInputSeekNegativeOverflowing, 0
	return Ok, base_pos - delta
}

impl Seek for Cursor {
	fn seek(pos<SeekFrom>) i32, u64 {
		base_pos<u64> = 0
		offset<i64> = 0

		match pos.tag {
			0 : {
				this.pos = pos.start_val
				return Ok, this.pos
			}
			1 : {
				base_pos = this.inner.len()
				offset = pos.offset_val
			}
			2 : {
				base_pos = this.pos
				offset = pos.offset_val
			}
			_ : return InvalidInput, 0
		}

		err<i32>, next_pos<u64> = checked_add_signed_u64(base_pos, offset)
		if err != Ok
			return err, 0
		this.pos = next_pos
		return Ok, this.pos
	}

	fn stream_len() i32, u64 {
		return Ok, this.inner.len()
	}

	fn stream_position() i32, u64 {
		return Ok, this.pos
	}
}

impl Read for Cursor {
	fn read(buf<Buf>) i32, u64 {
		remain<Buf> = this.remaining_slice()
		err<i32>, n<u64> = remain.read(buf)
		if err != Ok
			return err, 0
		this.pos += n
		return Ok, n
	}
}