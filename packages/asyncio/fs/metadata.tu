// File metadata and the fs_metadata entry point.

use std
use io
use string
use sys
use runtime

// Snapshot of a file's stat(2) result.
mem Metadata {
    u64 size        // st_size in bytes
    u32 mode        // st_mode (type bits + permission bits)
    u64 nlink
    u64 ino
    u64 mtime_sec
    u64 mtime_nsec
}

fn metadata_from_stat(s<std.Stat>) Metadata {
    m<Metadata> = new Metadata
    m.size       = s.st_size
    m.mode       = s.st_mode
    m.nlink      = s.st_nlink
    m.ino        = s.st_ino
    m.mtime_sec  = s.st_mtime[0]
    m.mtime_nsec = s.st_mtime[1]
    return m
}

Metadata::len() u64 {
    return this.size
}

// Cross-package size accessor (mem fields not visible outside asyncio.fs).
fn metadata_len(m<Metadata>) u64 {
    return m.size
}

Metadata::is_dir() i32 {
    raw<u32> = this.mode
    m<i64> = raw.(i64)
    if (m & std.S_IFMT) == std.S_IFDIR return 1
    return 0
}

Metadata::is_file() i32 {
    raw<u32> = this.mode
    m<i64> = raw.(i64)
    if (m & std.S_IFMT) == std.S_IFREG return 1
    return 0
}

Metadata::permissions() u32 {
    raw<u32> = this.mode
    m<i64> = raw.(i64)
    bits<i64> = m & 4095
    return bits.(u32)
}

mem MetadataFut: async {
    u64 path_bits
}

MetadataFut::poll(ctx) {
    s<std.Stat> = new std.Stat
    pc<i8*> = string.cstr_from_bits(this.path_bits)
    err<i32>, junk<u64> = sys.cvt(sys.stat(pc, s.(u64)))
    if err != io.Ok return runtime.PollReady, err, null
    return runtime.PollReady, io.Ok, metadata_from_stat(s)
}

fn fs_metadata(path_bits<u64>) runtime.Future {
    f<MetadataFut> = new MetadataFut { path_bits: path_bits }
    fut<runtime.Future> = f
    return fut
}

mem SymlinkMetadataFut: async {
    u64 path_bits
}

SymlinkMetadataFut::poll(ctx) {
    s<std.Stat> = new std.Stat
    pc<i8*> = string.cstr_from_bits(this.path_bits)
    err<i32>, junk<u64> = sys.cvt(sys.lstat(pc, s.(u64)))
    if err != io.Ok return runtime.PollReady, err, null
    return runtime.PollReady, io.Ok, metadata_from_stat(s)
}

fn fs_symlink_metadata(path_bits<u64>) SymlinkMetadataFut {
    return new SymlinkMetadataFut { path_bits: path_bits }
}
