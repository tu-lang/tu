// Growable byte buffer for merged __text / __data / bind opcodes / strtab.
// Backing store is noscan: object bytes and VAs must not be GC pointer-scanned.

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

// n zero bytes; used for hash-slot tables.
const ByteBuf::zeros(n<i32>) ByteBuf {
    b<ByteBuf> = ByteBuf::create()
    if n <= 0 {
        return b
    }
    b.reserve(n)
    n64<u64> = n
    std.memset(b.bits(), 0, n64)
    b.len = n
    return b
}

ByteBuf::i32_at(i<i32>) i32 {
    return this.read_i32(i * 4)
}

ByteBuf::set_i32(i<i32>, v<i32>) {
    this.set_u32_at(i * 4, i32_u32(v))
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
    this.push_u32(u64_u32(v))
    hi<u64> = v >> 32
    this.push_u32(u64_u32(hi))
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

ByteBuf::set_u64_at(off<i32>, v<u64>) {
    this.set_u32_at(off, u64_u32(v))
    hi<u64> = v >> 32
    this.set_u32_at(off + 4, u64_u32(hi))
}

ByteBuf::read_u64(off<i32>) u64 {
    if off + 8 > this.len {
        z<u64> = 0
        return z
    }
    return ru64(this.store + off)
}

ByteBuf::read_i32(off<i32>) i32 {
    if off + 4 > this.len {
        return 0
    }
    w<u32> = ru32(this.store + off)
    r<i32> = w
    return r
}

// Insert `n` zero bytes at `at`, shifting the tail right.
ByteBuf::insert_zeros(at<i32>, n<i32>) {
    if n <= 0 {
        return
    }
    this.reserve(n)
    i<i32> = this.len - 1
    loop {
        if i < at {
            break
        }
        src<i8*> = this.store + i
        dst<i8*> = this.store + i + n
        *dst = *src
        i -= 1
    }
    j<i32> = 0
    while j < n {
        z<i8*> = this.store + at + j
        *z = 0
        j += 1
    }
    this.len = this.len + n
}
