// fs_remove_file: unlink a file.

use io
use string
use sys
use runtime

// Leaf: unlink(2) on first poll.
mem RemoveFileFut: async {
    u64 path_bits
}

RemoveFileFut::poll(ctx) {
    pc<i8*> = string.cstr_from_bits(this.path_bits)
    err<i32>, junk<u64> = sys.cvt(sys.unlink(pc))
    return runtime.PollReady, err
}

fn fs_remove_file(path<string.String>) RemoveFileFut {
    return new RemoveFileFut { path_bits: string.string_to_bits(path) }
}
