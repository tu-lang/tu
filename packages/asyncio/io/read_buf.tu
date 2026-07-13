// Borrowed read buffer surfaced to AsyncRead implementors.
// Backed by io.buffer.Buffer; bytes are tracked via filled / init counts.

use io as iobuf

// Read-side cursor over an underlying io.buffer.Buffer.
mem ReadBuf {
    iobuf.Buffer* backing
    u64           filled    // bytes the reader has produced so far
}

// Build a ReadBuf wrapping `buf`. Initial filled = backing.filled.
const ReadBuf::new(buf<iobuf.Buffer>) ReadBuf {
    rb<ReadBuf> = new ReadBuf
    rb.backing  = buf
    rb.filled = buf.len()
    return rb
}

// Bytes filled so far (snapshot).
ReadBuf::filled_len() u64 {
    return this.filled
}

// Capacity of the backing Buffer.
ReadBuf::capacity() u64 {
    return this.backing.capacity()
}

// Free bytes in the backing buffer.
ReadBuf::remaining() u64 {
    return this.backing.capacity() - this.filled
}

// Pointer to the start of filled bytes in the backing store.
ReadBuf::data_ptr() u8* {
    return this.backing.backing.data_ptr
}

// Append `slice` to the filled region.
ReadBuf::put_slice(slice<iobuf.Buf>){
    base<iobuf.Buf> = this.backing.backing
    off<i32> = int(this.filled)
    base.copy_at(off, slice)
    this.filled = this.filled + slice.len()
    this.backing.filled = this.filled
    if this.backing.init < this.filled {
        this.backing.init = this.filled
    }
}

// Mark `n` more bytes as filled. Returns 0 on success, -1 when n exceeds remaining().
ReadBuf::advance(n<u64>) i32 {
    if n > this.remaining() return -1
    this.filled = this.filled + n
    this.backing.filled = this.filled
    if this.backing.init < this.filled {
        this.backing.init = this.filled
    }
    return 0
}

// Initialise the unfilled tail to zero.
ReadBuf::initialize_unfilled() iobuf.Buffer {
    cap<u64> = this.backing.capacity()
    if this.backing.init < cap {
        this.backing.init = cap
    }
    return this.backing
}
