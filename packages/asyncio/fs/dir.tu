// Directory reading (tokio::fs::read_dir): ReadDir stream + DirEntry.
// Backed by getdents64 over a directory fd; "." and ".." are filtered out.

use std
use io
use string
use sys

// getdents64 refill buffer size.
DIRENT_BUF_SIZE<i32> = 4096

// One raw linux_dirent64 record. d_name begins at offset 19 (right after the
// 1-byte d_type), so &d_name yields the NUL-terminated entry name.
mem Dirent64 {
    u64 d_ino
    i64 d_off
    u16 d_reclen    // total record length; used to step to the next entry
    u8  d_type      // DT_* file-type hint
    i8  d_name      // first byte of the NUL-terminated name
}

// A single directory entry.
mem DirEntry {
    string.String name
    u32           d_type
}

// Entry name.
DirEntry::file_name() string.String {
    return this.name
}

// True when the entry is a directory per its DT_ hint.
DirEntry::is_dir() bool {
    if this.d_type.(i32) == std.DT_DIR return true
    return false
}

// True when the entry is a regular file per its DT_ hint.
DirEntry::is_file() bool {
    if this.d_type.(i32) == std.DT_REG return true
    return false
}

// Lazy directory stream over a getdents64 buffer. buf_pos walks the current
// buffer; when exhausted, next_entry issues another getdents64.
mem ReadDir {
    i32 fd
    u8* buf
    i32 buf_size
    i32 buf_pos
    i32 buf_filled
}

// True for the "." / ".." self/parent entries, which are skipped.
fn is_dot_name(name<string.String>) bool {
    if name.cmpstr(*".") == 0 return true
    if name.cmpstr(*"..") == 0 return true
    return false
}

// Open `path` as a directory for iteration. Returns (io.Ok, ReadDir) or
// (err, null).
async fs_read_dir(path<string.String>) i32, ReadDir {
    err<i32>, fd<u64> = sys.cvt(sys_openat(AT_FDCWD, path.str(), std.O_RDONLY | std.O_DIRECTORY | O_CLOEXEC, 0))
    if err != io.Ok return err, null
    r<ReadDir> = new ReadDir
    r.fd         = fd.(i32)
    r.buf        = new DIRENT_BUF_SIZE
    r.buf_size   = DIRENT_BUF_SIZE
    r.buf_pos    = 0
    r.buf_filled = 0
    return io.Ok, r
}

// Next entry in the stream. Returns (io.Ok, DirEntry) for a real entry,
// (io.Ok, null) at end of stream, or (err, null) on failure.
async ReadDir::next_entry() i32, DirEntry {
    loop {
        if this.buf_pos >= this.buf_filled {
            err<i32>, n<u64> = sys.cvt(sys_getdents64(this.fd, this.buf, this.buf_size.(u64)))
            if err != io.Ok return err, null
            if n == 0 return io.Ok, null
            this.buf_filled = n.(i32)
            this.buf_pos    = 0
        }
        addr<u64> = (this.buf + this.buf_pos).(u64)
        d<Dirent64> = addr.(Dirent64)
        this.buf_pos += d.d_reclen.(i32)
        name<string.String> = string.S(&d.d_name)
        if is_dot_name(name) continue
        return io.Ok, new DirEntry { name: name, d_type: d.d_type.(u32) }
    }
}

// Close the directory fd. Returns io.Ok / error.
ReadDir::close() i32 {
    if this.fd < 0 return io.Ok
    err<i32>, _ = sys.cvt(sys_close(this.fd))
    this.fd = -1
    return err
}
