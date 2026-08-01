// fs_create_dir: create a single directory (mkdir).

use io
use string
use sys
use runtime

// Leaf: mkdir(2) with mode 0o777.
mem CreateDirFut: async {
    string.String path
}

CreateDirFut::poll(ctx) {
    pc<i8*> = string.cstr(this.path)
    mode_i<i64> = 493
    mraw<i32> = 0
    mraw = sys.mkdir(pc, mode_i)
    ok_code<i32> = io.Ok
    ready<i32> = runtime.PollReady
    if mraw >= 0 return ready, ok_code
    err<i32>, junk<u64> = sys.cvt(mraw)
    return ready, err
}

fn fs_create_dir(path<string.String>) CreateDirFut {
    return new CreateDirFut { path: path }
}
