// fs_copy: copy `from` to `to`, preserving permission bits.

use io
use string
use runtime

mem CopyFut: async {
    string.String from
    string.String to
}

CopyFut::poll(ctx) {
    oerr<i32>, src<File> = file_open_read_sync(this.from)
    if oerr != io.Ok return runtime.PollReady, oerr, 0.(u64)

    merr<i32>, meta<Metadata> = file_metadata_sync(src)
    mode<u32> = 420
    if merr == io.Ok mode = meta.permissions()

    o<OpenOptions> = OpenOptions::new()
    o = o.write(1)
    o = o.create(1)
    o = o.truncate(1)
    o = o.mode(mode)
    derr<i32>, dst<File> = file_open_sync(this.to, o)
    if derr != io.Ok {
        src.close()
        return runtime.PollReady, derr, 0.(u64)
    }

    buf<io.Buf> = io.NewBuf(8192)
    total<u64> = 0
    loop {
        rerr<i32>, n<u64> = file_read_sync(src, buf)
        if rerr != io.Ok {
            src.close()
            dst.close()
            return runtime.PollReady, rerr, 0.(u64)
        }
        if n == 0 break
        w<u64> = 0
        while w < n {
            slice<io.Buf> = io.buf_slice(buf, w, n - w)
            werr<i32>, wn<u64> = file_write_sync(dst, slice)
            if werr != io.Ok {
                src.close()
                dst.close()
                return runtime.PollReady, werr, 0.(u64)
            }
            if wn == 0 {
                src.close()
                dst.close()
                return runtime.PollReady, io.WriteZero, 0.(u64)
            }
            w += wn
        }
        total += n
    }
    src.close()
    dst.close()
    return runtime.PollReady, io.Ok, total
}

fn fs_copy(from<string.String>, to<string.String>) CopyFut {
    return new CopyFut {
        from: from,
        to: to
    }
}
