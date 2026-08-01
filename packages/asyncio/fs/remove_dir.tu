// fs_remove_dir: remove an empty directory.

use io
use string
use sys
use runtime

mem RemoveDirFut: async {
    string.String path
}

RemoveDirFut::poll(ctx) {
    pc<i8*> = string.cstr(this.path)
    raw_rm<i32> = 0
    raw_rm = sys.rmdir(pc)
    ok_code<i32> = io.Ok
    ready<i32> = runtime.PollReady
    if raw_rm >= 0 return ready, ok_code
    err<i32>, junk<u64> = sys.cvt(raw_rm)
    return ready, err
}

fn fs_remove_dir(path<string.String>) RemoveDirFut {
    return new RemoveDirFut { path: path }
}
