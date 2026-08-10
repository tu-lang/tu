// Growable byte buffer used when emitting Mach-O section contents.
// Backing store is noscan: section bytes must not be GC pointer-scanned.

use std
use runtime

mem ByteBuf {
    i8* store
    i32 len
    i32 cap
}

const ByteBuf::create() ByteBuf {
    b<ByteBuf> = new ByteBuf
    b.store = null
    b.len = 0
    b.cap = 0
    return b
}

// Heap pointer to the live bytes.
ByteBuf::ptr() i8* {
    return this.store
}

// Same pointer as u64 for fwrite / memset.
ByteBuf::bits() u64 {
    p<u64> = this.store
    return p
}

ByteBuf::reserve(need<i32>) {
    if this.len + need <= this.cap {
        return
    }
    ncap<i32> = this.cap
    if ncap < 64 {
        ncap = 64
    }
    loop {
        if ncap >= this.len + need {
            break
        }
        ncap = ncap * 2
    }
    ncap64<u64> = ncap
    bits<u64> = runtime.malloc(ncap64, 1.(i8), 1.(i8))
    p<i8*> = bits
    if this.len > 0 && this.store != null {
        n64<u64> = this.len
        std.memcpy(p, this.store, n64)
    }
    this.store = p
    this.cap = ncap
}

ByteBuf::push_u8(v<i32>) {
    this.reserve(1)
    p<i8*> = this.store + this.len
    *p = v.(i8)
    this.len = this.len + 1
}

ByteBuf::push_u32(v<u32>) {
    this.push_u8((v & 0xff).(i32))
    this.push_u8(((v >> 8) & 0xff).(i32))
    this.push_u8(((v >> 16) & 0xff).(i32))
    this.push_u8(((v >> 24) & 0xff).(i32))
}

ByteBuf::push_u64(v<u64>) {
    this.push_u32((v & 0xffffffff).(u32))
    this.push_u32(((v >> 32) & 0xffffffff).(u32))
}

ByteBuf::append(src<i8*>, n<i32>) {
    if n <= 0 {
        return
    }
    this.reserve(n)
    dst<i8*> = this.store + this.len
    n64<u64> = n
    std.memcpy(dst, src, n64)
    this.len = this.len + n
}

ByteBuf::align_to(a<i32>, pad<i32>) {
    if a <= 1 {
        return
    }
    loop {
        r<i32> = this.len % a
        if r == 0 {
            break
        }
        this.push_u8(pad)
    }
}

ByteBuf::set_u32_at(off<i32>, v<u32>) {
    p<i8*> = this.store + off
    p[0] = (v & 0xff).(i8)
    p[1] = ((v >> 8) & 0xff).(i8)
    p[2] = ((v >> 16) & 0xff).(i8)
    p[3] = ((v >> 24) & 0xff).(i8)
}
