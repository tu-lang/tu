// fs_remove_file: unlink a file.

use io
use string
use sys
use runtime

// Leaf: unlink(2) on first poll.
mem RemoveFileFut: async {
    string.String path
}

RemoveFileFut::poll(ctx) {
    pc<i8*> = string.cstr(this.path)
    err<i32>, junk<u64> = sys.cvt(sys.unlink(pc))
    return runtime.PollReady, err
}

fn fs_remove_file(path<string.String>) RemoveFileFut {
    return new RemoveFileFut { path: path }
}
