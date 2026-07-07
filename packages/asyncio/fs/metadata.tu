// File metadata (tokio::fs::Metadata) and the fs_metadata entry point.
// Wraps the subset of struct stat that the public API exposes.

use std
use io
use string
use sys

// Snapshot of a file's stat(2) result. mtime is split into whole seconds plus
// the nanosecond remainder to avoid 64-bit overflow when composed.
mem Metadata {
    u64 size        // st_size in bytes
    u32 mode        // st_mode (type bits + permission bits)
    u64 nlink       // hard-link count
    u64 ino         // inode number
    u64 mtime_sec   // st_mtime seconds
    u64 mtime_nsec  // st_mtime nanoseconds
}

// Build a Metadata from a populated std.Stat. st_mtime is a [sec, nsec] pair.
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

// File length in bytes.
Metadata::len() u64 {
    return this.size
}

// True when the entry is a directory ((mode & S_IFMT) == S_IFDIR).
Metadata::is_dir() bool {
    if (this.mode.(i64) & std.S_IFMT) == std.S_IFDIR return true
    return false
}

// True when the entry is a regular file ((mode & S_IFMT) == S_IFREG).
Metadata::is_file() bool {
    if (this.mode.(i64) & std.S_IFMT) == std.S_IFREG return true
    return false
}

// Permission bits only (mode & 0o7777).
Metadata::permissions() u32 {
    return (this.mode.(i64) & 4095).(u32)
}

// Metadata for `path` (stat, follows symlinks). Returns (io.Ok, Metadata) or
// (err, null).
async fs_metadata(path<string.String>) i32, Metadata {
    s<std.Stat> = new std.Stat
    err<i32>, _ = sys.cvt(sys_stat(path.str(), s))
    if err != io.Ok return err, null
    return io.Ok, metadata_from_stat(s)
}

// Metadata for `path` without following a terminal symlink (lstat).
async fs_symlink_metadata(path<string.String>) i32, Metadata {
    s<std.Stat> = new std.Stat
    err<i32>, _ = sys.cvt(sys_lstat(path.str(), s))
    if err != io.Ok return err, null
    return io.Ok, metadata_from_stat(s)
}
