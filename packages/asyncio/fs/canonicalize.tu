// fs_canonicalize.
// V1: readlink terminal symlink or return a copy of the input path.

use io
use string
use sys
use runtime

mem CanonicalizeFut: async {
    string.String path
}

CanonicalizeFut::poll(ctx) {
    pc<i8*> = string.cstr(this.path)
    buf<u8*> = new 4096
    err<i32>, n<u64> = sys.cvt(sys.readlink(pc, buf, 4096))
    if err == io.Ok {
        return runtime.PollReady, io.Ok, new string.String { inner: string.newlen(buf, n) }
    }
    if err == io.InvalidInput {
        return runtime.PollReady, io.Ok, this.path.dup()
    }
    return runtime.PollReady, err, null
}

fn fs_canonicalize(path<string.String>) CanonicalizeFut {
    return new CanonicalizeFut { path: path }
}
