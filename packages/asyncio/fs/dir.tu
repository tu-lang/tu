// Directory reading: ReadDir stream + DirEntry.
// Backed by getdents64 over a directory fd; "." and ".." are filtered out.
// Path args use string.String; dirent parse uses memcpy.

use std
use io
use string
use sys
use runtime

DIRENT_BUF_SIZE<i32> = 4096

mem DirEntry {
    u64 name_bits // owned cstr bits (GC buffer), not String*
    u32 kind      // linux_dirent64.d_type
}

DirEntry::file_name() string.String {
    return string.string_from_bits(this.name_bits)
}

// Cross-package name cstr.
fn dir_entry_name_cstr(ent<DirEntry>) i8* {
    return string.cstr_from_bits(ent.name_bits)
}

DirEntry::is_dir() i32 {
    t<u32> = this.kind
    dt_dir<i32> = 4
    if t.(i32) == dt_dir return 1
    return 0
}

DirEntry::is_file() i32 {
    t<u32> = this.kind
    dt_reg<i32> = 8
    if t.(i32) == dt_reg return 1
    return 0
}

mem ReadDir {
    i32 fd
    u8* dents
    i32 dents_cap
    i32 dents_pos
    i32 dents_len
}

fn is_dot_name_cstr(name_c<i8*>) i32 {
    if name_c == null return 0
    p0<i8*> = name_c
    p1<i8*> = name_c + 1
    p2<i8*> = name_c + 2
    c0<i8> = *p0
    c1<i8> = *p1
    c2<i8> = *p2
    if c0 == '.' && c1 == 0 return 1
    if c0 == '.' && c1 == '.' && c2 == 0 return 1
    return 0
}

// Sync open of a directory stream.
fn read_dir_open_sync(path_bits<u64>) i32, ReadDir {
    ok_code<i32> = io.Ok
    pc<i8*> = string.cstr_from_bits(path_bits)
    clo_raw = std.O_CLOEXEC
    clo<i64> = clo_raw.(i64)
    flags<i64> = std.O_RDONLY | clo
    mode_i<i64> = 0
    // Nested cvt(openat) keeps the fd; plain `raw = openat(...)` can drop it to 0.
    err<i32>, fd_u<u64> = sys.cvt(sys.openat(std.AT_FDCWD, pc, flags, mode_i))
    if err != ok_code return err, null
    r<ReadDir> = new ReadDir
    r.fd         = fd_u.(i32)
    alloc_n<i32> = DIRENT_BUF_SIZE
    r.dents      = new alloc_n
    r.dents_cap  = alloc_n
    r.dents_pos  = 0
    r.dents_len  = 0
    return ok_code, r
}

fn read_dir_open_sync_cstr(path_cstr<i8*>) i32, ReadDir {
    bits<u64> = path_cstr.(u64)
    err<i32>, r<ReadDir> = read_dir_open_sync(bits)
    return err, r
}

// Copy a cstr into a fresh GC buffer; return pointer bits.
fn dup_cstr_bits(src<i8*>) u64 {
    if src == null {
        empty<i8*> = new 1
        *empty = 0
        return empty.(u64)
    }
    n_u<u64> = std.strlen(src)
    n_i<i32> = n_u.(i32)
    alloc_n<i32> = n_i + 1
    dst<i8*> = new alloc_n
    std.memcpy(dst, src, n_u)
    end_p<i8*> = dst + n_i
    *end_p = 0
    return dst.(u64)
}

// Load u16 LE at buf+off via memcpy into a 2-byte slot.
fn load_u16_le(buf<u8*>, off<i32>) i32 {
    slot<u8*> = new 2
    src<u8*> = buf + off
    two<u64> = 2
    std.memcpy(slot, src, two)
    p0<u8*> = slot
    p1<u8*> = slot + 1
    b0<u8> = *p0
    b1<u8> = *p1
    lo<i32> = b0.(i32)
    hi<i32> = b1.(i32)
    return lo + hi * 256
}

// Sync next entry; returns (err, owned name bits). name bits == 0 at EOF.
fn read_dir_next_bits(rd<ReadDir>) i32, u64 {
    ok_code<i32> = io.Ok
    pos<i32> = rd.dents_pos
    filled<i32> = rd.dents_len
    base<u8*> = rd.dents
    loop {
        if pos >= filled {
            sz<i32> = rd.dents_cap
            count_u<u64> = 0
            count_u = sz.(u64)
            fd_i<i32> = rd.fd
            raw_g<i64> = 0
            raw_g = sys.getdents64(fd_i, base, count_u)
            if raw_g < 0 {
                rd.dents_pos = pos
                rd.dents_len = filled
                raw_i<i32> = 0
                raw_i = raw_g.(i32)
                err<i32>, junk<u64> = sys.cvt(raw_i)
                return err, 0
            }
            if raw_g == 0 {
                rd.dents_pos = 0
                rd.dents_len = 0
                return ok_code, 0
            }
            filled = raw_g.(i32)
            pos = 0
        }
        off_relen<i32> = pos + 16
        reclen_i<i32> = load_u16_le(base, off_relen)
        if reclen_i <= 0 {
            rd.dents_pos = pos
            rd.dents_len = filled
            return ok_code, 0
        }
        end_pos<i32> = pos + reclen_i
        if end_pos > filled {
            rd.dents_pos = pos
            rd.dents_len = filled
            return ok_code, 0
        }
        name_off<i32> = pos + 19
        name_src<u8*> = base + name_off
        name_c<i8*> = name_src
        if is_dot_name_cstr(name_c) != 0 {
            pos = end_pos
            continue
        }
        name_bits<u64> = dup_cstr_bits(name_c)
        pos = end_pos
        rd.dents_pos = pos
        rd.dents_len = filled
        return ok_code, name_bits
    }
}

ReadDir::close() i32 {
    ok_code<i32> = io.Ok
    if this.fd < 0 return ok_code
    raw_c<i32> = 0
    raw_c = sys.close(this.fd)
    this.fd = -1
    if raw_c >= 0 return ok_code
    err<i32>, junk<u64> = sys.cvt(raw_c)
    return err
}

// pad keeps async mem layout aligned with two-u64 leaf futures (WriteFut).
mem ReadDirFut: async {
    u64 path_bits
    u64 pad
}

ReadDirFut::poll(ctx) {
    err<i32>, r<ReadDir> = read_dir_open_sync(this.path_bits)
    ready<i32> = runtime.PollReady
    return ready, err, r
}

fn fs_read_dir(path<string.String>) ReadDirFut {
    return new ReadDirFut { path_bits: string.string_to_bits(path), pad: 0 }
}

mem NextEntryFut: async {
    u64 rd_bits // ReadDir as bits (persist cursor across await)
}

NextEntryFut::poll(ctx) {
    ready<i32> = runtime.PollReady
    bits<u64> = this.rd_bits
    rd<ReadDir> = bits
    err<i32>, nb<u64> = read_dir_next_bits(rd)
    // Second value is owned name bits; 0 means EOF.
    return ready, err, nb
}

fn fs_next_entry(rd<ReadDir>) NextEntryFut {
    bits<u64> = rd.(u64)
    return new NextEntryFut { rd_bits: bits }
}

// Cross-package close (member close from outside can mis-dispatch).
fn read_dir_close(rd<ReadDir>) i32 {
    err<i32> = rd.close()
    return err
}
