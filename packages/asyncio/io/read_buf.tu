// Borrowed read buffer surfaced to AsyncRead implementors.
// Backed by io.buffer.Buffer; bytes are tracked via filled / init counts.

use io as iobuf

// Read-side cursor over an underlying io.buffer.Buffer. `filled` mirrors
// the inner Buffer's filled count and is kept here so the user-facing
// API does not have to chase through the inner pointer on every poll.
mem ReadBuf {
    iobuf.Buffer* inner
    u64           filled    // bytes the reader has produced so far
}

// Build a ReadBuf wrapping `buf`. Initial filled = inner.filled.
const ReadBuf::new(buf<iobuf.Buffer>) ReadBuf {
    rb<ReadBuf> = new ReadBuf
    rb.inner  = buf
    rb.filled = buf.len()
    return rb
}

// Bytes filled so far (snapshot).
ReadBuf::filled_len() u64 {
    return this.filled
}

// Capacity of the backing Buffer.
ReadBuf::capacity() u64 {
    return this.inner.capacity()
}

// Free bytes in the backing buffer.
ReadBuf::remaining() u64 {
    return this.inner.capacity() - this.filled
}

// Append `slice` to the filled region. Caller must ensure
// `slice.len() <= remaining()`. Updates the inner Buffer's bookkeeping.
ReadBuf::put_slice(slice<iobuf.Buf>){
    base<iobuf.Buf> = this.inner.buf
    base.copy_at(this.filled.(i32), slice)
    this.filled = this.filled + slice.len()
    this.inner.filled = this.filled
    if this.inner.init < this.filled {
        this.inner.init = this.filled
    }
}

// Mark `n` more bytes as filled (for callers that wrote directly into the
// unfilled region). Returns 0 on success, -1 when n exceeds remaining().
ReadBuf::advance(n<u64>) i32 {
    if n > this.remaining() return -1
    this.filled = this.filled + n
    this.inner.filled = this.filled
    if this.inner.init < this.filled {
        this.inner.init = this.filled
    }
    return 0
}

// Initialise the unfilled tail to zero; useful before handing the slice
// to syscalls that read into uninitialised bytes. Returns the inner
// Buffer (chainable).
ReadBuf::initialize_unfilled() iobuf.Buffer {
    cap<u64> = this.inner.capacity()
    if this.inner.init < cap {
        this.inner.init = cap
    }
    return this.inner
}
