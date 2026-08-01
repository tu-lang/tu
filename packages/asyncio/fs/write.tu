// fs_write: create/truncate `path` and write all of `data`.

use io
use string
use runtime

// Leaf: create + write-all + close in one poll (V1 inline).
mem WriteFut: async {
    string.String path
    io.Buf        data
}

WriteFut::poll(ctx) {
    pc<i8*> = string.cstr(this.path)
    oerr<i32>, f<File> = file_create_sync_cstr(pc)
    if oerr != io.Ok return runtime.PollReady, oerr
    total<u64> = 0
    data<io.Buf> = this.data
    dlen<u64> = io.buf_len(data)
    while total < dlen {
        rem<u64> = dlen - total
        slice<io.Buf> = io.buf_slice(data, total, rem)
        werr<i32>, n<u64> = file_write_sync(f, slice)
        if werr != io.Ok {
            f.close()
            return runtime.PollReady, werr
        }
        if n == 0 {
            f.close()
            return runtime.PollReady, io.WriteZero
        }
        total += n
    }
    f.close()
    return runtime.PollReady, io.Ok
}

fn fs_write(path<string.String>, data<io.Buf>) WriteFut {
    return new WriteFut {
        path: path,
        data: data
    }
}
