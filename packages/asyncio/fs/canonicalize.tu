// fs_canonicalize.
// V1: readlink terminal symlink or return a copy of the input path.

use io
use string
use sys
use runtime

mem CanonicalizeFut: async {
    u64 path_bits
}

CanonicalizeFut::poll(ctx) {
    pc<i8*> = string.cstr_from_bits(this.path_bits)
    buf<u8*> = new 4096
    err<i32>, n<u64> = sys.cvt(sys.readlink(pc, buf, 4096))
    if err == io.Ok {
        return runtime.PollReady, io.Ok, new string.String { inner: string.newlen(buf, n) }
    }
    if err == io.InvalidInput {
        path_s<string.String> = string.string_from_bits(this.path_bits)
        return runtime.PollReady, io.Ok, path_s.dup()
    }
    return runtime.PollReady, err, null
}

fn fs_canonicalize(path<string.String>) CanonicalizeFut {
    return new CanonicalizeFut { path_bits: string.string_to_bits(path) }
}
