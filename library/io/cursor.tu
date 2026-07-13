use runtime

mem Cursor {
	Buf* backing
	u64 cursor_pos
}

const Cursor::new(backing<Buf>) Cursor {
	return new Cursor { cursor_pos: 0, backing: backing }
}

Cursor::into_inner() Buf {
	return this.backing
}

Cursor::get_ref() Buf {
	return this.backing
}

Cursor::get_mut() Buf {
	return this.backing
}

Cursor::position() u64 {
	return this.cursor_pos
}

Cursor::set_position(pos<u64>) {
	this.cursor_pos = pos
}

Cursor::remaining_slice() Buf {
	used<u64> = min_u64(this.cursor_pos, this.backing.len())
	return new Buf {
		data_ptr: this.backing.data_ptr + used,
		byte_len: this.backing.len() - used
	}
}

Cursor::is_empty() i32 {
	return this.cursor_pos >= this.backing.len()
}

Cursor::clone() Cursor {
	return new Cursor { backing: this.backing.dup(), cursor_pos: this.cursor_pos }
}

Cursor::clone_from(other<Cursor>) {
	this.backing = other.backing.dup()
	this.cursor_pos = other.cursor_pos
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
				this.cursor_pos = pos.start_val
				return Ok, this.cursor_pos
			}
			1 : {
				base_pos = this.backing.len()
				offset = pos.offset_val
			}
			2 : {
				base_pos = this.cursor_pos
				offset = pos.offset_val
			}
			_ : return InvalidInput, 0
		}

		err<i32>, next_pos<u64> = checked_add_signed_u64(base_pos, offset)
		if err != Ok
			return err, 0
		this.cursor_pos = next_pos
		return Ok, this.cursor_pos
	}

	fn stream_len() i32, u64 {
		return Ok, this.backing.len()
	}

	fn stream_position() i32, u64 {
		return Ok, this.cursor_pos
	}
}

impl Read for Cursor {
	fn read(buf<Buf>) i32, u64 {
		remain<Buf> = this.remaining_slice()
		err<i32>, n<u64> = remain.read(buf)
		if err != Ok
			return err, 0
		this.cursor_pos += n
		return Ok, n
	}
}
