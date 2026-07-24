// Async file handle (tokio::fs::File) plus open helpers.
//
// V1 runs each syscall synchronously inline on the calling task. tokio routes
// these through spawn_mandatory_blocking; public surface stays awaitable via
// leaf futures (sync factory returns runtime.Future for direct `.await`).

use std
use io
use string
use sys
use runtime

// An open file. fd is the raw descriptor; -1 once closed.
mem File {
    i32 fd
}

// Sync open used by leaf futures (mother OpenOptions::open).
fn file_open_sync(path_bits<u64>, opts<OpenOptions>) i32, File {
    err<i32>, f<File> = file_open_sync_cstr(string.cstr_from_bits(path_bits), opts)
    return err, f
}

fn file_open_sync_cstr(path_cstr<i8*>, opts<OpenOptions>) i32, File {
    ferr<i32>, flags<i64> = opts.to_flags()
    if ferr != io.Ok return ferr, null
    mode_u<u32> = opts.mode
    clo_raw = std.O_CLOEXEC
    clo<i64> = clo_raw.(i64)
    err<i32>, fd<u64> = sys.cvt(sys.openat(std.AT_FDCWD, path_cstr, flags | clo, mode_u.(i64)))
    if err != io.Ok return err, null
    return io.Ok, new File { fd: fd.(i32) }
}

fn file_open_read_sync(path_bits<u64>) i32, File {
    // Hardcoded O_RDONLY|O_CLOEXEC for V1 read path (same pattern as create).
    clo_raw = std.O_CLOEXEC
    clo<i64> = clo_raw.(i64)
    flags<i64> = std.O_RDONLY | clo
    mode_i<i64> = 0
    pc<i8*> = string.cstr_from_bits(path_bits)
    err<i32>, fd<u64> = sys.cvt(sys.openat(std.AT_FDCWD, pc, flags, mode_i))
    if err != io.Ok return err, null
    return io.Ok, new File { fd: fd.(i32) }
}

fn file_create_sync(path_bits<u64>) i32, File {
    // Cross-pkg String params are unsafe; take bits and recover cstr in string pkg.
    err<i32>, f<File> = file_create_sync_cstr(string.cstr_from_bits(path_bits))
    return err, f
}

fn file_create_sync_cstr(path_cstr<i8*>) i32, File {
    // O_WRONLY|O_CREAT|O_TRUNC|O_CLOEXEC — hardcoded for V1 create path
    // (avoids OpenOptions field loads until that path is hardened).
    clo_raw = std.O_CLOEXEC
    clo<i64> = clo_raw.(i64)
    flags<i64> = std.O_WRONLY | std.O_CREAT | std.O_TRUNC | clo
    mode_i<i64> = 420
    err<i32>, fd<u64> = sys.cvt(sys.openat(std.AT_FDCWD, path_cstr, flags, mode_i))
    if err != io.Ok return err, null
    return io.Ok, new File { fd: fd.(i32) }
}

// Sync read/write/close for leaf futures.
fn file_read_sync(f<File>, buf<io.Buf>) i32, u64 {
    err<i32>, n<u64> = sys.cvt(sys.read(f.fd, io.buf_ptr(buf), io.buf_len(buf)))
    if err != io.Ok return err, 0
    return io.Ok, n
}

fn file_write_sync(f<File>, buf<io.Buf>) i32, u64 {
    err<i32>, n<u64> = sys.cvt(sys.write(f.fd, io.buf_ptr(buf), io.buf_len(buf)))
    if err != io.Ok return err, 0
    return io.Ok, n
}

File::close() i32 {
    if this.fd < 0 return io.Ok
    err<i32>, junk<u64> = sys.cvt(sys.close(this.fd))
    this.fd = -1
    return err
}

fn file_metadata_sync(f<File>) i32, Metadata {
    s<std.Stat> = new std.Stat
    err<i32>, junk<u64> = sys.cvt(sys.fstat(f.fd, s.(u64)))
    if err != io.Ok return err, null
    return io.Ok, metadata_from_stat(s)
}

// ---- open leaf -----------------------------------------------------------

mem OpenFut: async {
    u64          path_bits
    OpenOptions* opts
}

OpenFut::poll(ctx) {
    err<i32>, f<File> = file_open_sync(this.path_bits, this.opts)
    return runtime.PollReady, err, f
}

fn fs_open(path_bits<u64>, opts<OpenOptions>) OpenFut {
    return new OpenFut { path_bits: path_bits, opts: opts }
}

mem OpenReadFut: async {
    u64 path_bits
}

OpenReadFut::poll(ctx) {
    err<i32>, f<File> = file_open_read_sync(this.path_bits)
    return runtime.PollReady, err, f
}

fn fs_open_read(path_bits<u64>) OpenReadFut {
    return new OpenReadFut { path_bits: path_bits }
}

mem CreateFut: async {
    u64 path_bits
}

CreateFut::poll(ctx) {
    err<i32>, f<File> = file_create_sync(this.path_bits)
    return runtime.PollReady, err, f
}

fn fs_create(path_bits<u64>) CreateFut {
    return new CreateFut { path_bits: path_bits }
}

// ---- File member leaf futures (tokio File::read / write / …) -------------

mem FileReadFut: async {
    File* file
    u64   buf_bits
}

FileReadFut::poll(ctx) {
    err<i32>, n<u64> = file_read_sync(this.file, io.buf_from_bits(this.buf_bits))
    return runtime.PollReady, err, n
}

fn file_read_fut(f<File>, buf<io.Buf>) FileReadFut {
    return new FileReadFut { file: f, buf_bits: io.buf_to_bits(buf) }
}

mem FileWriteFut: async {
    File* file
    u64   buf_bits
}

FileWriteFut::poll(ctx) {
    err<i32>, n<u64> = file_write_sync(this.file, io.buf_from_bits(this.buf_bits))
    return runtime.PollReady, err, n
}

fn file_write_fut(f<File>, buf<io.Buf>) FileWriteFut {
    return new FileWriteFut { file: f, buf_bits: io.buf_to_bits(buf) }
}

mem FileMetaFut: async {
    File* file
}

FileMetaFut::poll(ctx) {
    err<i32>, m<Metadata> = file_metadata_sync(this.file)
    return runtime.PollReady, err, m
}

async File::metadata() {
    return new FileMetaFut { file: this }
}

mem FileSyncAllFut: async {
    File* file
}

FileSyncAllFut::poll(ctx) {
    err<i32>, junk<u64> = sys.cvt(sys.fsync(this.file.fd))
    return runtime.PollReady, err
}

async File::sync_all() {
    return new FileSyncAllFut { file: this }
}

mem FileSyncDataFut: async {
    File* file
}

FileSyncDataFut::poll(ctx) {
    err<i32>, junk<u64> = sys.cvt(sys.fdatasync(this.file.fd))
    return runtime.PollReady, err
}

async File::sync_data() {
    return new FileSyncDataFut { file: this }
}

mem FileSetLenFut: async {
    File* file
    u64   n
}

FileSetLenFut::poll(ctx) {
    n_u<u64> = this.n
    err<i32>, junk<u64> = sys.cvt(sys.ftruncate(this.file.fd, n_u.(i64)))
    return runtime.PollReady, err
}

async File::set_len(n<u64>) {
    return new FileSetLenFut { file: this, n: n }
}

mem FileSeekFut: async {
    File*       file
    io.SeekFrom pos
}

FileSeekFut::poll(ctx) {
    whence<i64> = std.SEEK_SET
    off<i64> = 0
    if this.pos.tag == 0 {
        whence = std.SEEK_SET
        start_u<u64> = this.pos.start_val
        off = start_u.(i64)
    } else if this.pos.tag == 1 {
        whence = std.SEEK_END
        off = this.pos.offset_val
    } else {
        whence = std.SEEK_CUR
        off = this.pos.offset_val
    }
    err<i32>, at<u64> = sys.cvt(sys.lseek(this.file.fd, off, whence))
    if err != io.Ok return runtime.PollReady, err, 0.(u64)
    return runtime.PollReady, io.Ok, at
}

async File::seek(pos<io.SeekFrom>) {
    return new FileSeekFut { file: this, pos: pos }
}
