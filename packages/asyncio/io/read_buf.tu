// Borrowed read buffer surfaced to AsyncRead implementors.
// Filled/initialized cursor over a byte slice.
//
// This package must not `use io` (short-name clash with asyncio.io). Callers
// with an io.Buf may use `asyncio.io.util.read_buf_over`, or
// `read_buf_from_i8(buf.ptr(), n)` from a package that imports io.
//
// `start` is a real `u8*` so GC scans it (a former `u64 data_bits` left the
// byte region unrooted across gc_malloc).

use std

// Borrowed byte cursor. `start` must outlive this ReadBuf (caller-owned).
mem ReadBuf {
    u8* start  // GC-rooted base of the byte region
    u64 cap    // total capacity in bytes
    u64 filled // bytes written into the buffer
}

// Build ReadBuf from raw pointer bits (caller widens i8*/u8* → u64).
fn read_buf_from_bits_cap(data_bits<u64>, cap<u64>) ReadBuf {
    rb<ReadBuf> = new ReadBuf
    p<u8*> = null
    p = data_bits
    rb.start = p
    rb.cap = cap
    rb.filled = 0
    return rb
}

// Build ReadBuf from i8* (nested call args like from_i8(buf.ptr(), n) are OK).
fn read_buf_from_i8(data<i8*>, cap<u64>) ReadBuf {
    rb<ReadBuf> = new ReadBuf
    p<u8*> = null
    p = data
    rb.start = p
    rb.cap = cap
    rb.filled = 0
    return rb
}

// Start empty over an already-initialized region.
const ReadBuf::from_ptr(data<u8*>, cap<u64>) ReadBuf {
    rb<ReadBuf> = new ReadBuf
    rb.start = data
    rb.cap = cap
    rb.filled = 0
    return rb
}

// Package-level bridge for untyped call sites.
fn read_buf_from_ptr(data<u8*>, cap<u64>) ReadBuf {
    return ReadBuf::from_ptr(data, cap)
}

// u64 bridges for async leaf fields (typed ReadBuf* slots zero under async mem).
fn read_buf_to_bits(b<ReadBuf>) u64 {
    return b.(u64)
}

fn read_buf_from_bits(bits<u64>) ReadBuf {
    return bits.(ReadBuf)
}

// Expose stored pointer bits for diagnostics / cross-check.
fn read_buf_data_bits(b<ReadBuf>) u64 {
    bits<u64> = 0
    bits = b.start
    return bits
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
    return this.start
}

// Pointer to the first unfilled byte.
ReadBuf::unfilled_ptr() u8* {
    return this.start + this.filled
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
