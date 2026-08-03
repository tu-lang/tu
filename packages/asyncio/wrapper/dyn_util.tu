// Dyn string / buffer helpers used across wrapper modules (internal).

use io
use std
use string

// Convert a dynamic address/path/payload into string.String.
fn dyn_string(v) string.String {
    return string.S(v)
}

// Build io.Buf from dynamic string content.
fn dyn_buf(v) io.Buf {
    s<string.String> = dyn_string(v)
    slen<i32> = std.strlen(s.str())
    b<io.Buf> = io.NewBuf(slen)
    p<i8*> = b.ptr()
    std.memcpy(p, s.str(), slen.(u64))
    return b
}

// Copy filled buffer bytes into a dynamic string.
fn buf_to_dyn_string(buf<io.Buf>, n<u64>) {
    n_i<i32> = n.(i32)
    alloc_n<i32> = n_i + 1
    scratch<i8*> = new alloc_n
    std.memcpy(scratch, buf.ptr(), n)
    endp<i8*> = scratch + n_i
    *endp = 0
    return string.new(scratch)
}
