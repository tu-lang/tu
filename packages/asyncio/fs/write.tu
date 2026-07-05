// fs_write (tokio::fs::write): create/truncate `path` and write all of `data`.

use io
use string

// Write every byte of `data` to `path`, creating or truncating it (mode 0o644).
// Returns io.Ok, or io.WriteZero if the file stops accepting bytes early.
async fs_write(path<string.String>, data<io.Buf>) i32 {
    oerr<i32>, f<File> = fs_create(path).await
    if oerr != io.Ok return oerr
    total<u64> = 0
    while total < data.len() {
        slice<io.Buf> = new io.Buf { inner: data.ptr() + total, len: data.len() - total }
        werr<i32>, n<u64> = f.write(slice).await
        if werr != io.Ok {
            f.close()
            return werr
        }
        if n == 0 {
            f.close()
            return io.WriteZero
        }
        total += n
    }
    f.close()
    return io.Ok
}
