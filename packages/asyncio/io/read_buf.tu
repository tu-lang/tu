// Borrowed read buffer surfaced to AsyncRead implementors.
// Filled/initialized cursor over a byte slice.
//
// Package asyncio.io cannot `use io` (short-name clash with this package), so
// the buffer is held as a raw byte pointer + capacity (layout adaptation of
// the design ReadBuf over &[u8]).
//
// data_bits keeps the package bridge and async adapters representation-neutral.
// Native pointer and u64 mem fields preserve all 64 bits (struct.tu regression).

use std

mem ReadBuf {
    u64 data_bits // base of the byte region as raw pointer bits
    u64 cap       // total capacity in bytes
    u64 filled    // bytes written into the buffer
}

// Build ReadBuf from raw pointer bits (caller widens i8*/u8* → u64).
fn read_buf_from_bits_cap(data_bits<u64>, cap<u64>) ReadBuf {
    rb<ReadBuf> = new ReadBuf
    rb.data_bits = data_bits
    rb.cap = cap
    rb.filled = 0
    return rb
}

// Alternate entry from i8* (io.Buf::ptr). Widens via local u64 first.
fn read_buf_from_i8(data<i8*>, cap<u64>) ReadBuf {
    bits<u64> = 0
    bits = data
    return read_buf_from_bits_cap(bits, cap)
}

// Start empty over an already-initialized region.
const ReadBuf::from_ptr(data<u8*>, cap<u64>) ReadBuf {
    rb<ReadBuf> = new ReadBuf
    bits<u64> = 0
    bits = data
    rb.data_bits = bits
    rb.cap = cap
    rb.filled = 0
    return rb
}

// Package-level bridge. Cross-pkg `aio.ReadBuf::from_ptr` also works when the
// result is typed (`rb<aio.ReadBuf>`); this fn remains for untyped call sites.
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
    return b.data_bits
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
    p<u8*> = this.data_bits
    return p
}

// Pointer to the first unfilled byte.
ReadBuf::unfilled_ptr() u8* {
    base<u8*> = this.data_bits
    return base + this.filled
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
