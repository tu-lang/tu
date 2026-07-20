
use runtime
use std
Null<i64> = 0

mem Buf {
	u8* data_ptr
    u64 byte_len
}
func NewBuf(cap<i32>){
	return new Buf {
		data_ptr : new cap,
        byte_len: cap
	}
}

Buf::data(){
	return this.data_ptr
}
Buf::dup() {
    cp<u8*> = new this.byte_len
    std.memcpy(cp, this.data_ptr, this.byte_len)
	return new Buf {
		data_ptr : cp,
        byte_len: this.byte_len
	}
}

Buf::len(){
    return this.byte_len
}

Buf::ptr() i8* {
	return this.data_ptr
}

Buf::split_at(mid<u64>) Buf, Buf {
    if mid > this.len() {
        runtime.dief("Buf:: mid <= this.len() assert failed")
    }
    // SAFETY: `[ptr; mid]` and `[mid; len]` are inside `self`, which
    // fulfills the requirements of `split_at_unchecked`.
    total<i32> = this.len()
    ptr<u8*> = this.ptr()
    return new Buf {
        data_ptr: ptr,
        byte_len: mid
    },     new Buf {
        data_ptr: ptr + mid,
        byte_len: total - mid
    }
}
Buf::copy_at(pos<i32> , buf<Buf>) {
    if pos > this.byte_len
        runtime.dief("Buf::copy_at pos over len")
    least<i32> = this.byte_len - pos

    if buf.len() > least
        runtime.dief("Buf::copy_at buf over the capacity")

    ptr<u8*> = this.data_ptr + pos
    std.memcpy(ptr, buf.data_ptr, buf.len())
}

mem Buffer {
    Buf* backing
    u64 filled
    u64 init
}

/// Create a new `Buffer` from a fully initialized slice.
const Buffer::from(slice<Buf>) Buffer {
    total<i32> = slice.len()

    return new Buffer {
        // SAFETY: initialized data never becoming uninitialized is an invariant of Buffer
        backing: slice.ptr(),
        filled: 0,
        init: total,
    }
}

const Buffer::from_uinit(buf<Buf>) Buffer {
    return new Buffer {
        backing: buf,
        filled: 0,
        init: 0
    }
}

Buffer::capacity() u64 {
    return this.backing.len()
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
        data_ptr: this.backing.ptr(),
        byte_len: this.filled
    }
}

Buffer::unfilled() BufferCursor {
    return new BufferCursor {
        start: this.filled,
        // SAFETY: we never assign into `BufferCursor::owner`, so treating its
        // lifetime covariantly is safe.
        owner: this,
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

// Full capacity store (avoids cross-pkg `.backing` / method vs field `filled` traps).
Buffer::store_buf() Buf {
    return this.backing
}

Buffer::set_filled_count(n<u64>) {
    this.filled = n
}

Buffer::set_init_count(n<u64>) {
    if this.init < n {
        this.init = n
    }
}

// Cross-pkg casting (asyncio.io cannot `use io` — short name conflicts).
fn buffer_from_bits(bits<u64>) Buffer {
    return bits.(Buffer)
}

fn buffer_to_bits(b<Buffer>) u64 {
    return b.(u64)
}

fn buf_from_bits(bits<u64>) Buf {
    return bits.(Buf)
}

fn buf_to_bits(b<Buf>) u64 {
    return b.(u64)
}

// Cross-package field bridges (mem fields of Buf are not visible outside io).
fn buf_len(b<Buf>) u64 {
    return b.byte_len
}

fn buf_ptr(b<Buf>) i8* {
    return b.data_ptr
}

fn buf_memcpy_in(b<Buf>, src<i8*>, n<u64>) {
    std.memcpy(b.data_ptr, src, n)
}

// Borrowed sub-slice of b starting at off for len bytes.
fn buf_slice(b<Buf>, off<u64>, len<u64>) Buf {
    return new Buf {
        data_ptr: b.data_ptr + off,
        byte_len: len
    }
}

fn buf_with_len(b<Buf>, len<u64>) Buf {
    return new Buf {
        data_ptr: b.data_ptr,
        byte_len: len
    }
}

mem BufferCursor {
    Buffer* owner
    u64     start
}


BufferCursor::reborrow() BufferCursor {
    return new BufferCursor {
        owner: this.owner,
        start: this.start,
    }
}

/// Returns the available space in the cursor.
BufferCursor::capacity() u64 {
    return this.owner.capacity() - this.owner.filled
}

BufferCursor::written() u64 {
    return this.owner.filled - this.start
}

BufferCursor::init_ref() Buf {
    ptr<u8*> = this.owner.backing.data_ptr + this.owner.filled
    // SAFETY: We only slice the initialized part of the buffer, which is always valid
    return new Buf {
        data_ptr: ptr,
        byte_len: this.owner.init
    }
}

BufferCursor::init_mut() Buf {
    ptr<u8*> = this.owner.backing.data_ptr + this.owner.filled
    // SAFETY: We only slice the initialized part of the buffer, which is always valid
    return new Buf {
        data_ptr: ptr,
        byte_len: this.owner.init
    }
}

BufferCursor::uninit_mut() Buf {
    ptr<u8*> = this.owner.backing.data_ptr + this.owner.init
    // SAFETY: We only slice the initialized part of the buffer, which is always valid
    return new Buf {
        data_ptr: ptr,
        byte_len: this.owner.capacity() - this.owner.init
    }
}

BufferCursor::as_mut() Buf {
    ptr<u8*> = this.owner.backing.data_ptr + this.owner.filled
    // SAFETY: We only slice the initialized part of the buffer, which is always valid
    return new Buf {
        data_ptr: ptr,
        byte_len: this.owner.capacity() - this.owner.filled
    }
}

BufferCursor::advance(n<u64>) BufferCursor {
    this.owner.filled += n
    if this.owner.init < this.owner.filled {
        this.owner.init = this.owner.filled
    }
    return this
}

// Initializes all bytes in the cursor.
BufferCursor::ensure_init() BufferCursor {
    uninit<Buf> = this.uninit_mut()
    // SAFETY: 0 is a valid value for MaybeUninit<u8> and the length matches the allocation
    // since it is comes from a slice reference.

    std.memset(uninit.data_ptr, 0, uninit.len())
    this.owner.init = this.owner.capacity()
    return this
}

BufferCursor::set_init(n<u64>) BufferCursor {
    if this.owner.init < (this.owner.filled + n) {
        this.owner.init = this.owner.filled + n
    }
    return this
}

BufferCursor::append(buf<Buf>) {
    if this.capacity() >= buf.len() {
        runtime.dief("this.capacity() > buf.len()")
    }

    // SAFETY: we do not de-initialize any of the elements of the slice
    dst<Buf> = this.as_mut()
    std.memcpy(dst.ptr(), buf.ptr(), buf.len())

    // SAFETY: We just added the entire contents of buf to the filled section.
    this.set_init(buf.len())
    this.owner.filled += buf.len()
}

impl Write for BufferCursor {
    fn write(buf<Buf>) i32, u64 {
        this.append(buf)
        return Ok, buf.len()
    }
    fn flush() i32 {
        return Ok
    }
}
