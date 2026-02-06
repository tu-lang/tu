use sys
use runtime

DEFAULT_BUF_SIZE<i32> = 8 * 1024

fn min_u64(a<u64>, b<u64>) u64 {
	if a < b
		return a
	return b
}

fn default_read_to_end(r, buf<Buf>, size_hint_opt<i32>) i32, u64 {
	read_buf<Buffer> = Buffer::from_uinit(buf)
	read_buf.set_init(0)
	cursor<BufferCursor> = read_buf.unfilled()
	loop {
		cur<BufferCursor> = cursor.reborrow()
		err<i32> = r.read_buf(cur)
		if err != Ok
			if err == Interrupted
				continue
			else
				return err, 0
		if cursor.written() == 0
			return Ok, read_buf.len()
		return Ok, read_buf.len()
	}
}

fn default_read_vectored(r, buf<Buf>) i32, u64 {
	return r.read(buf)
}

fn default_write_vectored(w, buf<Buf>) i32, u64 {
	return w.write(buf)
}

fn default_read_exact(this, buf<Buf>) i32 {
	pos<u64> = 0
	loop {
		if pos >= buf.len()
			return Ok
		slice<Buf> = new Buf { inner: buf.inner + pos, len: buf.len() - pos }
		err<i32>, n<u64> = this.read(slice)
		if err != Ok
			if err == Interrupted
				continue
			else
				return err
		if n == 0
			return UnexpectedEofFailedFillWholeBuffer
		pos += n
	}
}

fn default_read_buf(this, cursor<BufferCursor>) i32 {
	cursor.ensure_init()
	b<Buf> = cursor.as_mut()
	err<i32>, n<u64> = this.read(b)
	if err != Ok
		return err
	cursor.advance(n)
	return Ok
}

api Read {
	fn read(buf<Buf>) (i32, u64)
	fn read_buf(cursor<BufferCursor>) i32 {
		return default_read_buf(this, cursor)
	}
	fn read_to_end(buf<Buf>) i32, u64 {
		return default_read_to_end(this, buf, 0)
	}
	fn read_exact(buf<Buf>) i32 {
		return default_read_exact(this, buf)
	}
	fn read_vectored(buf<Buf>) i32, u64 {
		return default_read_vectored(this, buf)
	}
	fn is_read_vectored() bool {
		return false
	}
	fn take(limit<u64>) Take {
		return Take_new(this, limit)
	}
}

mem SeekFrom {
	i32 tag
	u64 start_val
	i64 offset_val
}

fn SeekFrom_start(n<u64>) SeekFrom {
	return new SeekFrom { tag: 0, start_val: n, offset_val: 0 }
}

fn SeekFrom_end(n<i64>) SeekFrom {
	return new SeekFrom { tag: 1, start_val: 0, offset_val: n }
}

fn SeekFrom_current(n<i64>) SeekFrom {
	return new SeekFrom { tag: 2, start_val: 0, offset_val: n }
}

api Seek {
	fn seek(pos<SeekFrom>) (i32, u64)
	fn rewind() i32 {
		err<i32>, _<u64> = this.seek(SeekFrom_start(0))
		return err
	}
	fn stream_len() (i32, u64)
	fn stream_position() i32, u64 {
		return this.seek(SeekFrom_current(0))
	}
}

api Write {
	fn write(buf<Buf>) (i32, u64)
	fn write_vectored(buf<Buf>) i32, u64 {
		return default_write_vectored(this, buf)
	}
	fn is_write_vectored() bool {
		return false
	}
	fn flush() (i32)
	fn write_all(buf<Buf>) i32 {
		pos<u64> = 0
		loop {
			if pos >= buf.len()
				return Ok
			slice<Buf> = new Buf { inner: buf.inner + pos, len: buf.len() - pos }
			err<i32>, n<u64> = this.write(slice)
			if err != Ok
				if err == Interrupted
					continue
				else
					return err
			if n == 0
				return WriteZeroFailedToWriteWholeBuffer
			pos += n
		}
	}
}

mem Take {
	inner
	u64 limit
}

fn Take_new(inner, limit<u64>) Take {
	return new Take { inner: inner, limit: limit }
}

impl Read for Take {
	fn read(buf<Buf>) i32, u64 {
		if this.limit == 0
			return Ok, 0
		cap<u64> = buf.len()
		if this.limit < cap
			cap = this.limit
		slice<Buf> = new Buf { inner: buf.inner, len: cap }
		err<i32>, n<u64> = this.inner.read(slice)
		if err != Ok
			return err, 0
		if n > this.limit
			runtime.dief("Take::read n > limit")
		this.limit -= n
		return Ok, n
	}
	fn read_buf(cursor<BufferCursor>) i32 {
		if this.limit == 0
			return Ok
		cur<BufferCursor> = cursor.reborrow()
		err<i32> = this.inner.read_buf(cur)
		if err != Ok
			return err
		written<u64> = cursor.written()
		if written > this.limit
			runtime.dief("Take::read_buf written > limit")
		this.limit -= written
		return Ok
	}
}
