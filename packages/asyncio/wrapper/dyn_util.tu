// Dyn string / buffer helpers used across wrapper modules (internal).
// Examples pass dynamic strings/ints; convert to mem types here.

use io
use std
use string
use runtime

// Convert a dynamic string value into string.String (GC-traced mem).
// Dynamic `"..."` is runtime.Value{type:String,data:cstr}; do NOT pass it to
// string.S as if it were i8* — that treats the Value object as a C string.
fn dyn_string(v) string.String {
    if v == null {
        return string.emptyS()
    }
    rv<runtime.Value> = v
    if rv.type != runtime.String {
        // Native i8* / cstr path (legacy callers).
        return string.S(v)
    }
    return new string.String {
        inner: rv.data
    }
}

// Dynamic int → i32 (Value.data holds the integer payload).
fn dyn_i32(v) i32 {
    if v == null {
        return 0
    }
    rv<runtime.Value> = v
    if rv.type == runtime.Int {
        return rv.data
    }
    // Already a native integer slot.
    n<i32> = v
    return n
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
