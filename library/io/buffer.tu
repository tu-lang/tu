
use runtime
use std
Null<i64> = 0

mem Buf {
	u8* inner
    u64 len
}
func NewBuf(len<i32>){
	return new Buf {
		inner : new len,
        len: len
	}
}

Buf::data(){
	return this.inner
}
Buf::dup() {
    cp<u8*> = new this.len
    std.memcpy(cp,this.inner,this.len)
	return new Buf {
		inner : cp,
        len: this.len
	}
}

Buf::len(){
    return this.len
}

Buf::ptr() i8* {
	return this.inner
}

mem Buffer {
    Buf* buf
    u64 filled
    u64 init
}

/// Create a new `Buffer` from a fully initialized slice.
const Buffer::from(slice<Buf>) Buffer {
    len<i32> = slice.len()

    return new Buffer {
        // SAFETY: initialized data never becoming uninitialized is an invariant of Buffer
        buf: slice.ptr(),
        filled: 0,
        init: len,
    }
}

const Buffer::from_uinit(buf<Buf>) Buffer {
    return new Buffer { 
        buf: buf, 
        filled: 0, 
        init: 0 
    }
}

Buffer::capacity() u64 {
    return this.buf.len()
}

Buffer::len() u64 {
    return this.filled
}

Buffer::init_len() u64 {
    return this.init
}

Buffer::filled() Buf {
    // SAFETY: We only slice the filled part of the buffer, which is always valid
    return new Buf {
        inner: this.buf.ptr(),
        len: this.filled
    }
}

Buffer::unfilled() BufferCursor {
    return new BufferCursor {
        start: this.filled,
        // SAFETY: we never assign into `BufferCursor::buf`, so treating its
        // lifetime covariantly is safe.
        buf: this,
    }
}

Buffer::clear() Buffer {
    this.filled = 0
    return this
}

Buffer::set_init(n<u64>) Buffer {
    if this.init < n {
        this.init = n
    }
    return this
}

mem BufferCursor {
    Buffer* buf
    u64     start
}

    
BufferCursor::reborrow() BufferCursor {
    return new BufferCursor {
        buf: this.buf,
        start: this.start,
    }
}

/// Returns the available space in the cursor.
BufferCursor::capacity() u64 {
    return this.buf.capacity() - this.buf.filled
}

BufferCursor::written() u64 {
    return this.buf.filled - this.start
}

BufferCursor::init_ref() Buf {
    ptr<u8*> = this.buf.buf.inner + this.buf.filled
    // SAFETY: We only slice the initialized part of the buffer, which is always valid
    return Buf {
        inner: ptr,
        len: this.buf.init
    }
}

BufferCursor::init_mut() Buf {
    ptr<u8*> = this.buf.buf.inner + this.buf.filled
    // SAFETY: We only slice the initialized part of the buffer, which is always valid
    return Buf {
        inner: ptr,
        len: this.buf.init
    }
}

BufferCursor::uninit_mut() Buf {
    ptr<u8*> = this.buf.buf.inner + this.buf.init
    // SAFETY: We only slice the initialized part of the buffer, which is always valid
    return Buf {
        inner: ptr,
        len: this.buf.capacity() - this.buf.init
    }
}

BufferCursor::as_mut() Buf {
    ptr<u8*> = this.buf.buf.inner + this.buf.filled
    // SAFETY: We only slice the initialized part of the buffer, which is always valid
    return Buf {
        inner: ptr,
        len: this.buf.capacity() - this.buf.filled
    }
}

BufferCursor::advance(n<u64>) BufferCursor {
    this.buf.filled += n
    if this.buf.init < this.buf.filled {
        this.buf.init = this.buf.filled
    }
}

/// Initializes all bytes in the cursor.
BufferCursor::ensure_init() BufferCursor {
    uninit<Buf> = this.uninit_mut();
    // SAFETY: 0 is a valid value for MaybeUninit<u8> and the length matches the allocation
    // since it is comes from a slice reference.

    std.memset(uninit.inner,0,uninit.len())
    this.buf.init = this.buf.capacity()
    return this
}

BufferCursor::set_init(n<u64>) BufferCursor {
    if this.buf.init < (this.buf.filled + n) {
        this.buf.init = this.buf.filled + n
    }
    return this
}

BufferCursor::append(buf<Buf>) {
    if this.capacity() >= buf.len() {
        runtime.dief("this.capacity() > buf.len()")
    }

    // SAFETY: we do not de-initialize any of the elements of the slice
    dst<Buf> = this.as_mut()
    std.memcpy(dst.ptr(), buf.ptr(),buf.len())

    // SAFETY: We just added the entire contents of buf to the filled section.
    this.set_init(buf.len())
    this.buf.filled += buf.len()
}

impl Write for BufferCursor {
    fn write(buf<Buf>) i32,u64 {
        this.append(buf)
        return Ok , buf.len()
    }
}

