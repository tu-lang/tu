// fs_read (tokio::fs::read): read a whole file into a freshly allocated io.Buf.
// Sizes the initial buffer from the file's metadata and grows on demand.

use std
use io
use string

// Read the entire contents of `path`. Returns (io.Ok, Buf) sized to the exact
// byte count, or (err, null) on failure.
async fs_read(path<string.String>) i32, io.Buf {
    oerr<i32>, f<File> = fs_open_read(path).await
    if oerr != io.Ok return oerr, null

    merr<i32>, meta<Metadata> = f.metadata().await
    cap<u64> = 8192
    if merr == io.Ok && meta.len() > 0 cap = meta.len()

    buf<io.Buf> = io.NewBuf(cap.(i32))
    total<u64> = 0
    loop {
        if total >= buf.len() {
            grown<io.Buf> = io.NewBuf((buf.len() * 2).(i32))
            std.memcpy(grown.ptr(), buf.ptr(), total)
            buf = grown
        }
        slice<io.Buf> = new io.Buf { inner: buf.ptr() + total, len: buf.len() - total }
        rerr<i32>, n<u64> = f.read(slice).await
        if rerr != io.Ok {
            f.close()
            return rerr, null
        }
        if n == 0 break
        total += n
    }
    f.close()
    return io.Ok, new io.Buf { inner: buf.ptr(), len: total }
}
