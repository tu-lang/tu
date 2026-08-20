// Noscan byte buffer + integer conversions for the self-hosted PE linker.
// Object/PE bytes and VAs must not be GC pointer-scanned.

use std
use runtime

fn ru16(src<i8*>) u16 {
    b<u8*> = src
    b0<u16> = b[0]
    b1<u16> = b[1]
    return b0 | (b1 << 8)
}

fn ru32(src<i8*>) u32 {
    b<u8*> = src
    b0<u32> = b[0]
    b1<u32> = b[1]
    b2<u32> = b[2]
    b3<u32> = b[3]
    return b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)
}

fn ru64(p<i8*>) u64 {
    lo<u64> = ru32(p)
    hi<u64> = ru32(p + 4)
    return lo | (hi << 32)
}

fn ri16(src<i8*>) i16 {
    w<u16> = ru16(src)
    r<i16> = w
    return r
}

// Hash-table byte count. Untyped `64 * 4` is compiled as a boxed multiply and
// the heap pointer is then read as i32, so reserve spins forever.
fn ht_bytes(nslot<i32>) i32 {
    w<i32> = 4
    return nslot * w
}

fn pe_zero(n<i32>) u64 {
    z<u64> = 0
    if n <= 0 {
        return z
    }
    n64<u64> = n
    bits<u64> = runtime.malloc(n64, 1.(i8), 1.(i8))
    std.memset(bits, 0, n64)
    return bits
}

fn i32_u64(v<i32>) u64 {
    r<u64> = v
    return r
}

fn i32_u32(v<i32>) u32 {
    r<u32> = v
    return r
}

mem U32Cell {
    u32 bits
}

mem U64Cell {
    u64 bits
}

conv32<U32Cell> = null
conv64<U64Cell> = null
conv_ready<i32> = 0

fn conv_init() {
    if conv_ready != 0 {
        return
    }
    conv32 = pe_zero(4)
    conv64 = pe_zero(8)
    conv_ready = 1
}

fn conv32_cell() U32Cell {
    conv_init()
    return conv32
}

fn conv64_cell() U64Cell {
    conv_init()
    return conv64
}

fn u32_i32(v<u32>) i32 {
    c<U32Cell> = conv32_cell()
    c.bits = v
    b<u8*> = c
    x0<i32> = b[0]
    x1<i32> = b[1]
    x2<i32> = b[2]
    x3<i32> = b[3]
    return x0 | (x1 << 8) | (x2 << 16) | (x3 << 24)
}

fn u32_u64(v<u32>) u64 {
    r<u64> = v
    return r
}

fn u64_i32(v<u64>) i32 {
    c<U64Cell> = conv64_cell()
    c.bits = v
    b<u8*> = c
    x0<i32> = b[0]
    x1<i32> = b[1]
    x2<i32> = b[2]
    x3<i32> = b[3]
    return x0 | (x1 << 8) | (x2 << 16) | (x3 << 24)
}

fn u64_u32(v<u64>) u32 {
    c<U64Cell> = conv64_cell()
    c.bits = v
    b<u8*> = c
    x0<u32> = b[0]
    x1<u32> = b[1]
    x2<u32> = b[2]
    x3<u32> = b[3]
    return x0 | (x1 << 8) | (x2 << 16) | (x3 << 24)
}

fn u64_i64(v<u64>) i64 {
    r<i64> = v
    return r
}

fn i64_u32(v<i64>) u32 {
    r<u32> = v
    return r
}

fn i64_u64(v<i64>) u64 {
    r<u64> = v
    return r
}

fn pe_align_u32(v<u32>, a<u32>) u32 {
    if a <= 1.(u32) {
        return v
    }
    return (v + a - 1.(u32)) & ~(a - 1.(u32))
}

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

ByteBuf::ptr() i8* {
    return this.store
}

ByteBuf::bits() u64 {
    p<u64> = this.store
    return p
}

ByteBuf::reserve(need<i32>) {
    if need < 0 {
        runtime.dief(*"peff ByteBuf reserve negative")
    }
    total<i32> = this.len + need
    if total < this.len {
        runtime.dief(*"peff ByteBuf reserve overflow")
    }
    if total <= this.cap {
        return
    }
    ncap<i32> = this.cap
    if ncap < 64 {
        ncap = 64
    }
    lim<i32> = 1073741823
    loop {
        if ncap >= total {
            break
        }
        if ncap > lim {
            runtime.dief(*"peff ByteBuf cap overflow")
        }
        ncap = ncap * 2
    }
    ncap64<u64> = ncap
    bits<u64> = runtime.malloc(ncap64, 1.(i8), 1.(i8))
    if bits == 0.(u64) {
        return
    }
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

ByteBuf::push_u16(v<u32>) {
    this.push_u8((v & 0xff).(i32))
    this.push_u8(((v >> 8) & 0xff).(i32))
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

ByteBuf::pad_to(off<i32>) {
    loop {
        if this.len >= off {
            break
        }
        this.push_u8(0)
    }
}

ByteBuf::set_u32_at(off<i32>, v<u32>) {
    if this.store == null || off < 0 || this.cap < 4 || off > this.cap - 4 {
        runtime.dief(*"peff set_u32_at OOB")
    }
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

ByteBuf::read_u32(off<i32>) u32 {
    if off + 4 > this.len {
        z<u32> = 0
        return z
    }
    return ru32(this.store + off)
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
