// fs_read: read a whole file into a freshly allocated io.Buf.

use std
use io
use string
use runtime

// Leaf: open + read-to-end + close in one poll (V1 inline).
mem ReadFut: async {
    string.String path
}

ReadFut::poll(ctx) {
    oerr<i32>, f<File> = file_open_read_sync(this.path)
    if oerr != io.Ok return runtime.PollReady, oerr, null

    cap_i<i32> = 8192
    buf<io.Buf> = io.NewBuf(cap_i)
    total<u64> = 0
    loop {
        blen<u64> = io.buf_len(buf)
        if total >= blen {
            next_cap_u<u64> = blen * 2
            next_cap_i<i32> = 0
            next_cap_i = next_cap_u
            grown<io.Buf> = io.NewBuf(next_cap_i)
            std.memcpy(io.buf_ptr(grown), io.buf_ptr(buf), total)
            buf = grown
            blen = io.buf_len(buf)
        }
        rem<u64> = blen - total
        slice<io.Buf> = io.buf_slice(buf, total, rem)
        rerr<i32>, n<u64> = file_read_sync(f, slice)
        if rerr != io.Ok {
            f.close()
            return runtime.PollReady, rerr, null
        }
        if n == 0 break
        total += n
    }
    f.close()
    return runtime.PollReady, io.Ok, io.buf_with_len(buf, total)
}

fn fs_read(path<string.String>) ReadFut {
    return new ReadFut { path: path }
}
