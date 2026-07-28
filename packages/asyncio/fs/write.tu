// fs_write: create/truncate `path` and write all of `data`.

use io
use string
use runtime

// Leaf: create + write-all + close in one poll (V1 inline).
// Public API takes string.String; async mem stores owned cstr bits.
mem WriteFut: async {
    u64 path_bits
    u64 data_bits
}

WriteFut::poll(ctx) {
    pc<i8*> = string.cstr_from_bits(this.path_bits)
    oerr<i32>, f<File> = file_create_sync_cstr(pc)
    if oerr != io.Ok return runtime.PollReady, oerr
    total<u64> = 0
    bits<u64> = this.data_bits
    data<io.Buf> = io.buf_from_bits(bits)
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

fn fs_write(path<string.String>, data_bits<u64>) runtime.Future {
    f<WriteFut> = new WriteFut {
        path_bits: string.string_to_bits(path),
        data_bits: data_bits
    }
    fut<runtime.Future> = f
    return fut
}
