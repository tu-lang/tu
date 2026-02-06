impl Write for Buf {
	fn write(buf<Buf>) i32, u64 {
		amt<u64> = buf.len()
		if this.len() < amt
			amt = this.len()
		if amt == 0
			return Ok, 0
		a<Buf>, _<Buf> = buf.split_at(amt)
		this.copy_at(0, a)
		return Ok, amt
	}
}

impl Write for Buffer {
	fn write(buf<Buf>) i32, u64 {
		cursor<BufferCursor> = this.unfilled()
		if buf.len() > cursor.capacity()
			return Uncategorized, 0
		cursor.append(buf)
		return Ok, buf.len()
	}
}

impl Read for Buf {
	fn read(buf<Buf>) i32, u64 {
		amt<u64> = buf.len()
		if this.len() < amt
			amt = this.len()
		a<Buf>, b<Buf> = this.split_at(amt)
		if amt == 1
			buf.inner[0] = a.inner[0]
		else
			buf.copy_at(0, a)
		this.inner = b.inner
		this.len = b.len
		return Ok, amt
	}
	fn read_buf(cursor<BufferCursor>) i32 {
		amt<u64> = cursor.capacity()
		if this.len() < amt
			amt = this.len()
		a<Buf>, b<Buf> = this.split_at(amt)
		cursor.append(a)
		this.inner = b.inner
		this.len = b.len
		return Ok
	}
}
