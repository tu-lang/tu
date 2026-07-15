// Borrowed read buffer surfaced to AsyncRead implementors.
// Mother: tokio::io::ReadBuf — filled/initialized cursor over a byte slice.
//
// Package asyncio.io cannot `use io` (short-name clash with this package), so
// the buffer is held as a raw byte pointer + capacity (layout adaptation of
// mother ReadBuf over &[u8]). Callers owning an io.Buf construct via
// ReadBuf::from_ptr(b.ptr(), b.len()).

use std

mem ReadBuf {
    u8* data   // base of the byte region
    u64 cap    // total capacity in bytes
    u64 filled // bytes written into the buffer
}

// Mother: ReadBuf::new — start empty over an already-initialized region.
const ReadBuf::from_ptr(data<u8*>, cap<u64>) ReadBuf {
    rb<ReadBuf> = new ReadBuf
    rb.data = data
    rb.cap = cap
    rb.filled = 0
    return rb
}

ReadBuf::filled_len() u64 {
    return this.filled
}

ReadBuf::capacity() u64 {
    return this.cap
}

ReadBuf::remaining() u64 {
    return this.cap - this.filled
}

// Base pointer of the whole buffer (filled region starts here).
ReadBuf::data_ptr() u8* {
    return this.data
}

// Pointer to the first unfilled byte.
ReadBuf::unfilled_ptr() u8* {
    return this.data + this.filled
}

ReadBuf::advance(n<u64>) i32 {
    if n > this.remaining() return -1
    this.filled = this.filled + n
    return 0
}

// Copy `n` bytes from `src` into the unfilled region and advance.
ReadBuf::put_bytes(src<u8*>, n<u64>) i32 {
    if n > this.remaining() return -1
    dst<u8*> = this.unfilled_ptr()
    std.memcpy(dst, src, n)
    this.filled = this.filled + n
    return 0
}
