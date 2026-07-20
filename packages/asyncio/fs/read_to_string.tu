// fs_read_to_string (tokio::fs::read_to_string): read a file and validate UTF-8.

use std
use io
use string
use runtime

fn is_valid_utf8(buf<io.Buf>) i32 {
    p<u8*> = io.buf_ptr(buf)
    len<u64> = io.buf_len(buf)
    i<u64> = 0
    while i < len {
        c<u8> = p[i]
        if c < 128 {
            i += 1
            continue
        }
        cont<u64> = 0
        ci<i32> = c.(i32)
        if (ci & 224) == 192 {
            cont = 1
        } else if (ci & 240) == 224 {
            cont = 2
        } else if (ci & 248) == 240 {
            cont = 3
        } else {
            return 0
        }
        if i + cont >= len return 0
        j<u64> = 1
        while j <= cont {
            b<u8> = p[i + j]
            bi<i32> = b.(i32)
            if (bi & 192) != 128 return 0
            j += 1
        }
        i += cont + 1
    }
    return 1
}

mem ReadToStringFut: async {
    u64 path_bits
}

ReadToStringFut::poll(ctx) {
    oerr<i32>, f<File> = file_open_read_sync(this.path_bits)
    if oerr != io.Ok return runtime.PollReady, oerr, null
    merr<i32>, meta<Metadata> = file_metadata_sync(f)
    cap<u64> = 8192
    if merr == io.Ok && meta.size > 0 cap = meta.size
    buf<io.Buf> = io.NewBuf(cap.(i32))
    total<u64> = 0
    loop {
        if total >= io.buf_len(buf) {
            next_cap<u64> = io.buf_len(buf) * 2
            grown<io.Buf> = io.NewBuf(next_cap.(i32))
            std.memcpy(io.buf_ptr(grown), io.buf_ptr(buf), total)
            buf = grown
        }
        slice<io.Buf> = io.buf_slice(buf, total, io.buf_len(buf) - total)
        rerr<i32>, n<u64> = file_read_sync(f, slice)
        if rerr != io.Ok {
            f.close()
            return runtime.PollReady, rerr, null
        }
        if n == 0 break
        total += n
    }
    f.close()
    out<io.Buf> = io.buf_with_len(buf, total)
    if is_valid_utf8(out) == 0 return runtime.PollReady, io.InvalidData, null
    s<string.String> = new string.String { inner: string.newlen(io.buf_ptr(out), io.buf_len(out)) }
    return runtime.PollReady, io.Ok, s
}

fn fs_read_to_string(path_bits<u64>) ReadToStringFut {
    return new ReadToStringFut { path_bits: path_bits }
}
