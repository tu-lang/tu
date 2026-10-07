use runtime
use std
use os

// Byte cursor over a text buffer with line/column tracking, for hand-written lexers.
// Static core is mem Cursor; untyped callers use CursorObj via cursor_open / cursor_text.
// Characters are returned as Char values and end-of-input as Int -1.

CURSOR_EOF<i32> = -1

// Read position over an owned, NUL-terminated byte buffer.
mem Cursor {
	i8* bytes      // buffer start; owned by the cursor (or by the native caller)
	i32 nbytes     // logical length, excluding the trailing NUL
	i32 pos        // offset of the next unread byte
	i32 line       // 1-based line, advanced by skip_space
	i32 column     // bytes read on the current line
}

// Wraps an existing native buffer; the caller keeps buf alive.
fn cursor_from_native(buf<i8*>, sz<i32>) Cursor {
	return new Cursor {
		bytes: buf,
		nbytes: sz,
		pos: 0,
		line: 1,
		column: 0
	}
}

// Copies a dyn string into a fresh buffer so the cursor owns its bytes.
fn cursor_from_string(s) Cursor {
	n<i32> = 0
	src<i8*> = 0
	if s != null {
		sv<runtime.Value> = s
		if sv.type != runtime.String {
			os.die("string.cursor_text: argument must be a string")
		}
		src = sv.data
		n = sv.data.(Str).len()
	}
	alloc_n<i32> = n + 1
	dst<i8*> = new alloc_n
	if n > 0 {
		std.memcpy(dst, src, n.(u64))
	}
	dst[n] = 0
	return cursor_from_native(dst, n)
}

// Reads a whole file into a cursor. Returns 0 and the cursor, or 1 on open/read failure.
fn cursor_open(path) (i32, u64) {
	if path == null {
		return 1, 0.(u64)
	}
	pv<runtime.Value> = path
	if pv.type != runtime.String {
		return 1, 0.(u64)
	}
	fd<i64> = std.fopen(pv.data, *"r")
	if fd < 0 {
		return 1, 0.(u64)
	}
	sz<i64> = std.fseek(fd, 0.(i64), std.SEEK_END)
	std.fseek(fd, 0.(i64), std.SEEK_SET)
	if sz < 0 {
		std.fclose(fd)
		return 1, 0.(u64)
	}
	n<i32> = sz
	alloc_n<i32> = n + 1
	dst<i8*> = new alloc_n
	got<i64> = 0
	bp<u64*> = dst
	if n > 0 {
		got = std.read(fd, bp, n.(u64))
	}
	std.fclose(fd)
	if got != sz {
		return 1, 0.(u64)
	}
	dst[n] = 0
	c<Cursor> = cursor_from_native(dst, n)
	return 0, c
}

// Consumes one byte; returns it (0..255) or CURSOR_EOF. Reading past EOF twice is fatal
// so a lexer loop that ignores EOF cannot spin forever.
Cursor::next() i32 {
	if this.pos >= this.nbytes {
		if this.pos > this.nbytes {
			os.dief("[error] cursor read past end pos:%d len:%d", int(this.pos), int(this.nbytes))
		}
		this.pos += 1
		return CURSOR_EOF
	}
	this.column += 1
	p<u8*> = this.bytes
	ch<u8> = p[this.pos]
	this.pos += 1
	return ch
}

// Returns the byte at pos + k without consuming, or CURSOR_EOF.
Cursor::peek_at(k<i32>) i32 {
	at<i32> = this.pos + k
	if at < 0 || at >= this.nbytes {
		return CURSOR_EOF
	}
	p<u8*> = this.bytes
	ch<u8> = p[at]
	return ch
}

Cursor::peek() i32 {
	return this.peek_at(0)
}

// Skips spaces, tabs, CR and LF (LF bumps line and resets column).
// Returns the next unread byte or CURSOR_EOF.
Cursor::skip_space() i32 {
	loop {
		ch<i32> = this.peek()
		if ch == ' ' || ch == '\t' || ch == '\r' {
			this.next()
		} else if ch == '\n' {
			this.next()
			this.line += 1
			this.column = 0
		} else {
			return ch
		}
	}
}

// Consumes bytes up to, but not including, the next LF.
Cursor::skip_line() {
	loop {
		ch<i32> = this.peek()
		if ch == '\n' || ch == CURSOR_EOF {
			return 0
		}
		this.next()
	}
}

// Returns bytes [from, to) as a dyn string (clamped to the buffer).
Cursor::slice(from<i32>, to<i32>) {
	lo<i32> = from
	hi<i32> = to
	if lo < 0 lo = 0
	if hi > this.nbytes hi = this.nbytes
	if hi < lo hi = lo
	base<i8*> = this.bytes
	return newstringfromlen(base + lo, hi - lo)
}

// Byte classes for take_run.
CURSOR_IDENT<i32> = 0   // [A-Za-z0-9_]
CURSOR_DIGIT<i32> = 1   // [0-9]
CURSOR_ALNUM<i32> = 2   // [A-Za-z0-9]

fn cursor_in_class(ch<i32>, cls<i32>) i32 {
	if ch >= '0' && ch <= '9' return 1
	if cls == CURSOR_DIGIT return 0
	if ch >= 'a' && ch <= 'z' return 1
	if ch >= 'A' && ch <= 'Z' return 1
	if cls == CURSOR_IDENT && ch == '_' return 1
	return 0
}

// Consumes the longest run of bytes in class cls; returns it as a dyn string (may be "").
Cursor::take_run(cls<i32>) {
	start<i32> = this.pos
	loop {
		ch<i32> = this.peek()
		if ch == CURSOR_EOF || cursor_in_class(ch, cls) == 0 {
			break
		}
		this.next()
	}
	return this.slice(start, this.pos)
}

// Reads a quoted body after the opening quote was consumed. Escapes are kept verbatim
// (backslash plus next byte). Consumes the closing quote.
// Returns 0 and the body, or 1 and the partial body when input ends first.
Cursor::take_quoted(q<i32>) i32, u64 {
	start<i32> = this.pos
	loop {
		ch<i32> = this.peek()
		if ch == CURSOR_EOF {
			partial<u64> = this.slice(start, this.pos)
			return 1, partial
		}
		if ch == q {
			body<u64> = this.slice(start, this.pos)
			this.next()
			return 0, body
		}
		this.next()
		if ch == '\\' {
			if this.peek() == CURSOR_EOF {
				tail<u64> = this.slice(start, this.pos)
				return 1, tail
			}
			this.next()
		}
	}
}

// Boxes a byte as a dyn Char, or CURSOR_EOF as Int -1.
fn cursor_char_value(ch<i32>) {
	if ch < 0 {
		eof<i64> = -1
		return int(eof)
	}
	cn<u8> = ch
	return runtime.newobject(runtime.Char, cn)
}

fn cursor_int_arg(v) i32 {
	if v == null return 0
	iv<runtime.Value> = v
	n<i32> = iv.data
	return n
}

// Dynamic facade so untyped code can lex without mem annotations.
class CursorObj {
	inner
	func init(c) {
		this.inner = c
	}
}

// Opens a file. Returns 0 and a CursorObj, or 1 and null.
export func cursor_open_file(path) {
	err<i32>, bits<u64> = cursor_open(path)
	if err != 0 {
		return 1, null
	}
	c<Cursor> = bits.(Cursor)
	obj = new CursorObj(c)
	return 0, obj
}

// Cursor over a copy of string s.
export func cursor_text(s) {
	c<Cursor> = cursor_from_string(s)
	return new CursorObj(c)
}

export func cursor_next(inner) {
	c<Cursor> = inner.(Cursor)
	return cursor_char_value(c.next())
}
export func cursor_peek(inner, k) {
	c<Cursor> = inner.(Cursor)
	return cursor_char_value(c.peek_at(cursor_int_arg(k)))
}
export func cursor_skip_space(inner) {
	c<Cursor> = inner.(Cursor)
	return cursor_char_value(c.skip_space())
}
export func cursor_skip_line(inner) {
	c<Cursor> = inner.(Cursor)
	c.skip_line()
}
export func cursor_take(inner, cls) {
	c<Cursor> = inner.(Cursor)
	return c.take_run(cursor_int_arg(cls))
}
export func cursor_quoted(inner, q) {
	c<Cursor> = inner.(Cursor)
	qv<runtime.Value> = q
	qc<i32> = qv.data
	err<i32>, body<u64> = c.take_quoted(qc)
	return int(err), body
}
export func cursor_slice(inner, from, to) {
	c<Cursor> = inner.(Cursor)
	return c.slice(cursor_int_arg(from), cursor_int_arg(to))
}
export func cursor_get(inner, field) {
	c<Cursor> = inner.(Cursor)
	f<i32> = cursor_int_arg(field)
	v<i64> = 0
	match f {
		0 : v = c.pos
		1 : v = c.line
		2 : v = c.column
		3 : v = c.nbytes
	}
	return int(v)
}
export func cursor_set(inner, field, value) {
	c<Cursor> = inner.(Cursor)
	f<i32> = cursor_int_arg(field)
	n<i32> = cursor_int_arg(value)
	match f {
		0 : c.pos = n
		1 : c.line = n
		2 : c.column = n
	}
}

// Consumes one byte (Char) or returns -1 at end of input.
CursorObj::next() { return cursor_next(this.inner) }
// Byte at the cursor without consuming it.
CursorObj::peek() { return cursor_peek(this.inner, 0) }
// Byte k positions ahead without consuming it.
CursorObj::peekAt(k) { return cursor_peek(this.inner, k) }
// Skips blanks/newlines (tracking lines); returns the next byte.
CursorObj::skipSpace() { return cursor_skip_space(this.inner) }
// Consumes up to (not including) the next newline.
CursorObj::skipLine() { cursor_skip_line(this.inner) }
// Longest run of [A-Za-z0-9_].
CursorObj::ident() { return cursor_take(this.inner, 0) }
// Longest run of [0-9].
CursorObj::digits() { return cursor_take(this.inner, 1) }
// Longest run of [A-Za-z0-9].
CursorObj::alnum() { return cursor_take(this.inner, 2) }
// Body up to the closing quote q (escapes verbatim). Returns err, body.
CursorObj::quoted(q) {
	err, body = cursor_quoted(this.inner, q)
	return err, body
}
// Bytes [from, to) as a string.
CursorObj::slice(from, to) { return cursor_slice(this.inner, from, to) }
CursorObj::pos() { return cursor_get(this.inner, 0) }
CursorObj::line() { return cursor_get(this.inner, 1) }
CursorObj::column() { return cursor_get(this.inner, 2) }
CursorObj::size() { return cursor_get(this.inner, 3) }
CursorObj::setPos(n) { cursor_set(this.inner, 0, n) }
CursorObj::setLine(n) { cursor_set(this.inner, 1, n) }
CursorObj::setColumn(n) { cursor_set(this.inner, 2, n) }
