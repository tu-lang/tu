// fs_copy (tokio::fs::copy): copy `from` to `to`, preserving permission bits,
// and return the number of bytes copied.

use io
use string

// Copy the whole file. Returns (io.Ok, bytes_copied) or (err, 0). The
// destination is created/truncated with the source's permission bits.
async fs_copy(from<string.String>, to<string.String>) i32, u64 {
    oerr<i32>, src<File> = fs_open_read(from).await
    if oerr != io.Ok return oerr, 0

    merr<i32>, meta<Metadata> = src.metadata().await
    mode<u32> = 420
    if merr == io.Ok mode = meta.permissions()

    o<OpenOptions> = OpenOptions::new()
    o = o.write(true)
    o = o.create(true)
    o = o.truncate(true)
    o = o.mode(mode)
    derr<i32>, dst<File> = fs_open(to, o).await
    if derr != io.Ok {
        src.close()
        return derr, 0
    }

    buf<io.Buf> = io.NewBuf(8192)
    total<u64> = 0
    loop {
        rerr<i32>, n<u64> = src.read(buf).await
        if rerr != io.Ok {
            src.close()
            dst.close()
            return rerr, 0
        }
        if n == 0 break
        w<u64> = 0
        while w < n {
            slice<io.Buf> = new io.Buf { inner: buf.ptr() + w, len: n - w }
            werr<i32>, wn<u64> = dst.write(slice).await
            if werr != io.Ok {
                src.close()
                dst.close()
                return werr, 0
            }
            if wn == 0 {
                src.close()
                dst.close()
                return io.WriteZero, 0
            }
            w += wn
        }
        total += n
    }
    src.close()
    dst.close()
    return io.Ok, total
}
