// Async file handle (tokio::fs::File) plus the fs_open entry point.
//
// V1 runs each syscall synchronously inline on the calling task. tokio routes
// these through spawn_mandatory_blocking so the reactor thread never blocks;
// that dispatch lands once the blocking-pool JoinHandle await path (runtime
// task 8.x follow-up) is wired. The public surface is kept async so callers
// `.await` File ops today and the body swaps to a blocking-pool future later.

use std
use io
use string
use sys

// openat dir fd meaning "resolve relative to the current working directory".
AT_FDCWD<i32> = -100
// O_CLOEXEC (Linux x86_64): close the fd across exec. Absent from std/header.
O_CLOEXEC<i64> = 524288

// An open file. fd is the raw descriptor; blocking-pool routing is deferred so
// no Spawner handle is cached yet (see file header).
mem File {
    i32 fd      // raw open fd, or -1 once closed
}

// Open `path` with `opts`. Returns (io.Ok, File) or (err, null) when the
// option combination is invalid or openat fails.
async fs_open(path<string.String>, opts<OpenOptions>) i32, File {
    ferr<i32>, flags<i64> = opts.to_flags()
    if ferr != io.Ok return ferr, null
    err<i32>, fd<u64> = sys.cvt(sys_openat(AT_FDCWD, path.str(), flags | O_CLOEXEC, opts.mode.(i64)))
    if err != io.Ok return err, null
    return io.Ok, new File { fd: fd.(i32) }
}

// Convenience: open `path` read-only.
async fs_open_read(path<string.String>) i32, File {
    o<OpenOptions> = OpenOptions::new()
    o = o.read(true)
    return fs_open(path, o).await
}

// Convenience: create/truncate `path` write-only (mode 0o644).
async fs_create(path<string.String>) i32, File {
    o<OpenOptions> = OpenOptions::new()
    o = o.write(true)
    o = o.create(true)
    o = o.truncate(true)
    o = o.mode(420)
    return fs_open(path, o).await
}

// Read up to buf.len() bytes into `buf`. Returns (io.Ok, n) with n==0 at EOF.
async File::read(buf<io.Buf>) i32, u64 {
    err<i32>, n<u64> = sys.cvt(sys_read(this.fd, buf.ptr(), buf.len()))
    if err != io.Ok return err, 0
    return io.Ok, n
}

// Write up to buf.len() bytes from `buf`. Returns (io.Ok, n) written.
async File::write(buf<io.Buf>) i32, u64 {
    err<i32>, n<u64> = sys.cvt(sys_write(this.fd, buf.ptr(), buf.len()))
    if err != io.Ok return err, 0
    return io.Ok, n
}

// Seek to `pos`. Returns (io.Ok, new_offset). Maps io.SeekFrom tags 0/1/2 to
// SEEK_SET / SEEK_END / SEEK_CUR.
async File::seek(pos<io.SeekFrom>) i32, u64 {
    whence<i64> = std.SEEK_SET
    off<i64>    = 0
    if pos.tag == 0 {
        whence = std.SEEK_SET
        off    = pos.start_val.(i64)
    } else if pos.tag == 1 {
        whence = std.SEEK_END
        off    = pos.offset_val
    } else {
        whence = std.SEEK_CUR
        off    = pos.offset_val
    }
    err<i32>, at<u64> = sys.cvt(sys_lseek(this.fd, off, whence))
    if err != io.Ok return err, 0
    return io.Ok, at
}

// Flush file data + metadata to disk (fsync). Returns io.Ok / error.
async File::sync_all() i32 {
    err<i32>, _ = sys.cvt(sys_fsync(this.fd))
    return err
}

// Flush file data only (fdatasync). Returns io.Ok / error.
async File::sync_data() i32 {
    err<i32>, _ = sys.cvt(sys_fdatasync(this.fd))
    return err
}

// Truncate / extend the file to `n` bytes (ftruncate). Returns io.Ok / error.
async File::set_len(n<u64>) i32 {
    err<i32>, _ = sys.cvt(sys_ftruncate(this.fd, n.(i64)))
    return err
}

// Metadata for the open fd (fstat). Returns (io.Ok, Metadata) or (err, null).
async File::metadata() i32, Metadata {
    s<std.Stat> = new std.Stat
    err<i32>, _ = sys.cvt(sys_fstat(this.fd, s))
    if err != io.Ok return err, null
    return io.Ok, metadata_from_stat(s)
}

// Close the underlying fd. Idempotent-ish: fd is set to -1 afterwards.
File::close() i32 {
    if this.fd < 0 return io.Ok
    err<i32>, _ = sys.cvt(sys_close(this.fd))
    this.fd = -1
    return err
}
