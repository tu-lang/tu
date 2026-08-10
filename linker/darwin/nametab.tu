// Interned C-string pool in Mach-O strtab shape: leading NUL, then name\0...
// Offsets are n_strx values; identical bytes share one offset.
// Open-addressing hash on the pool keeps intern O(1) at tulang scale.

use std

fn cstr_len(p<i8*>) i32 {
    i<i32> = 0
    loop {
        if p[i] == 0 {
            return i
        }
        i += 1
    }
}

fn name_eq_bytes(a<i8*>, b<i8*>, n<i32>) i32 {
    i<i32> = 0
    while i < n {
        if a[i] != b[i] {
            return 0
        }
        i += 1
    }
    return 1
}

fn bytes_hash(p<i8*>, n<i32>) u32 {
    h<u32> = 0x811C9DC5
    i<i32> = 0
    while i < n {
        pb<u8*> = p + i
        b<u32> = *pb
        h = h ^ b
        h = h * 0x01000193
        i += 1
    }
    return h
}

fn mix32(k<i32>) u32 {
    u<u32> = i32_u32(k)
    u = u * 0x9E3779B1
    return u
}

fn ht_mask(nslot<i32>) u32 {
    return i32_u32(nslot - 1)
}

fn ht_index(h<u32>, nslot<i32>) i32 {
    return u32_i32(h & ht_mask(nslot))
}

// i32→i32 open addressing. Key 0 is empty (strtab leading NUL is never a name).
mem OffMap {
    ByteBuf* keys
    ByteBuf* vals
    i32 nslot
    i32 nused
}

const OffMap::create() OffMap {
    m<OffMap> = new OffMap
    m.nslot = 64
    m.nused = 0
    m.keys = ByteBuf::zeros(64 * 4)
    m.vals = ByteBuf::zeros(64 * 4)
    return m
}

OffMap::grow() {
    oldk<ByteBuf> = this.keys
    oldv<ByteBuf> = this.vals
    oldn<i32> = this.nslot
    this.nslot = this.nslot * 2
    this.nused = 0
    this.keys = ByteBuf::zeros(this.nslot * 4)
    this.vals = ByteBuf::zeros(this.nslot * 4)
    j<i32> = 0
    while j < oldn {
        k<i32> = oldk.i32_at(j)
        if k != 0 {
            this.put(k, oldv.i32_at(j))
        }
        j += 1
    }
}

OffMap::put(k<i32>, v<i32>) {
    if k == 0 {
        return
    }
    if this.nused * 10 >= this.nslot * 7 {
        this.grow()
    }
    i<i32> = ht_index(mix32(k), this.nslot)
    loop {
        kk<i32> = this.keys.i32_at(i)
        if kk == 0 {
            this.keys.set_i32(i, k)
            this.vals.set_i32(i, v)
            this.nused += 1
            return
        }
        if kk == k {
            this.vals.set_i32(i, v)
            return
        }
        i = ht_index(i32_u32(i) + 1, this.nslot)
    }
}

OffMap::get(k<i32>) i32 {
    if k == 0 {
        return -1
    }
    i<i32> = ht_index(mix32(k), this.nslot)
    loop {
        kk<i32> = this.keys.i32_at(i)
        if kk == 0 {
            return -1
        }
        if kk == k {
            return this.vals.i32_at(i)
        }
        i = ht_index(i32_u32(i) + 1, this.nslot)
    }
}

mem NameTab {
    ByteBuf* buf
    ByteBuf* ht
    i32 nslot
    i32 nused
}

fn nametab_ht_new(nslot<i32>) ByteBuf {
    return ByteBuf::zeros(nslot * 4)
}

const NameTab::create() NameTab {
    t<NameTab> = new NameTab
    t.buf = ByteBuf::create()
    t.buf.push_u8(0)
    t.nslot = 64
    t.nused = 0
    t.ht = nametab_ht_new(64)
    return t
}

const NameTab::from_bytes(src<i8*>, n<i32>) NameTab {
    t<NameTab> = new NameTab
    t.buf = ByteBuf::create()
    if n > 0 {
        t.buf.append(src, n)
    } else {
        t.buf.push_u8(0)
    }
    t.nslot = 64
    t.nused = 0
    t.ht = nametab_ht_new(64)
    t.reindex()
    return t
}

NameTab::strsize() i32 {
    return this.buf.len
}

NameTab::ptr() i8* {
    return this.buf.ptr()
}

NameTab::bits() u64 {
    return this.buf.bits()
}

NameTab::align_strtab() {
    this.buf.align_to(8, 0)
}

NameTab::ptr_at(off<i32>) i8* {
    return this.buf.ptr() + off
}

NameTab::len_at(off<i32>) i32 {
    p<i8*> = this.buf.ptr() + off
    limit<i32> = this.buf.len - off
    i<i32> = 0
    loop {
        if i >= limit {
            return i
        }
        if p[i] == 0 {
            return i
        }
        i += 1
    }
}

NameTab::put(src<i8*>, n<i32>) i32 {
    off<i32> = this.buf.len
    if n > 0 {
        this.buf.append(src, n)
    }
    this.buf.push_u8(0)
    return off
}

NameTab::ht_place(off<i32>) {
    nn<i32> = this.len_at(off)
    h<u32> = bytes_hash(this.ptr_at(off), nn)
    i<i32> = ht_index(h, this.nslot)
    loop {
        cur<i32> = this.ht.i32_at(i)
        if cur == 0 {
            this.ht.set_i32(i, off)
            this.nused += 1
            return
        }
        i = ht_index(i32_u32(i) + 1, this.nslot)
    }
}

NameTab::rehash() {
    old<ByteBuf> = this.ht
    oldn<i32> = this.nslot
    this.nslot = this.nslot * 2
    this.nused = 0
    this.ht = nametab_ht_new(this.nslot)
    j<i32> = 0
    while j < oldn {
        off<i32> = old.i32_at(j)
        if off != 0 {
            this.ht_place(off)
        }
        j += 1
    }
}

// Rebuild hash from the live strtab (from_bytes / after bulk copy).
NameTab::reindex() {
    if this.nslot < 64 {
        this.nslot = 64
    }
    this.nused = 0
    this.ht = nametab_ht_new(this.nslot)
    pos<i32> = 1
    total<i32> = this.buf.len
    store<i8*> = this.buf.ptr()
    while pos < total {
        ln<i32> = 0
        loop {
            if pos + ln >= total {
                break
            }
            c<i8*> = store + pos + ln
            if *c == 0 {
                break
            }
            ln += 1
        }
        if ln > 0 {
            if this.nused * 10 >= this.nslot * 7 {
                this.rehash()
            }
            this.ht_place(pos)
        }
        pos = pos + ln + 1
        loop {
            if pos >= total {
                break
            }
            z<i8*> = store + pos
            if *z != 0 {
                break
            }
            pos += 1
        }
    }
}

// Find existing name\0 or append.
NameTab::intern(src<i8*>, n<i32>) i32 {
    nn<i32> = n
    if nn < 0 {
        nn = 0
    }
    if this.nused * 10 >= this.nslot * 7 {
        this.rehash()
    }
    h<u32> = bytes_hash(src, nn)
    i<i32> = ht_index(h, this.nslot)
    loop {
        off<i32> = this.ht.i32_at(i)
        if off == 0 {
            noff<i32> = this.put(src, nn)
            this.ht.set_i32(i, noff)
            this.nused += 1
            return noff
        }
        if this.len_at(off) == nn {
            if name_eq_bytes(this.ptr_at(off), src, nn) != 0 {
                return off
            }
        }
        i = ht_index(i32_u32(i) + 1, this.nslot)
    }
}

NameTab::intern_off(other<NameTab>, off<i32>) i32 {
    return this.intern(other.ptr_at(off), other.len_at(off))
}

NameTab::intern_cstr(lit<i8*>) i32 {
    return this.intern(lit, cstr_len(lit))
}

fn name_eq_cstr(tab<NameTab>, off<i32>, lit<i8*>) i32 {
    n<i32> = cstr_len(lit)
    if tab.len_at(off) != n {
        return 0
    }
    return name_eq_bytes(tab.ptr_at(off), lit, n)
}
