// fs_create_dir_all: create `path` and every
// missing parent, treating already-existing components as success.

use std
use io
use string
use sys
use runtime

// mkdir that tolerates an existing directory. Mode 0o755.
fn mkdir_ok_exists_cstr(path_cstr<i8*>) i32 {
    mode_i<i64> = 493
    err<i32>, junk<u64> = sys.cvt(sys.mkdir(path_cstr, mode_i))
    if err == io.Ok return io.Ok
    if err == io.AlreadyExists return io.Ok
    return err
}

// Leaf: walk "/" prefixes and mkdir each (V1 inline, one poll).
// Uses a mutable cstr copy so prefixes do not need String::sub across packages.
mem CreateDirAllFut: async {
    u64 path_bits
    u64 pad
}

CreateDirAllFut::poll(ctx) {
    ready<i32> = runtime.PollReady
    ok_code<i32> = io.Ok
    bad_in<i32> = io.InvalidInput
    src<i8*> = string.cstr_from_bits(this.path_bits)
    plen_u<u64> = std.strlen(src)
    plen<i32> = plen_u.(i32)
    if plen == 0 return ready, bad_in
    // `new plen + 1` parses as (new plen)+1; allocate with an explicit size.
    alloc_n<i32> = plen + 1
    tmp<i8*> = new alloc_n
    std.memcpy(tmp, src, plen_u)
    endp<i8*> = tmp + plen
    *endp = 0
    i<i32> = 0
    first<i8*> = tmp
    if *first == '/' i = 1
    while i <= plen {
        cur<i8*> = tmp + i
        at_end<i32> = 0
        if i == plen at_end = 1
        is_slash<i32> = 0
        if at_end == 0 {
            ch<i8> = *cur
            if ch == '/' is_slash = 1
        }
        if at_end != 0 || is_slash != 0 {
            if i > 0 {
                save<i8> = *cur
                *cur = 0
                merr<i32> = mkdir_ok_exists_cstr(tmp)
                *cur = save
                if merr != ok_code return ready, merr
            }
        }
        i += 1
    }
    return ready, ok_code
}

fn fs_create_dir_all(path<string.String>) CreateDirAllFut {
    return new CreateDirAllFut { path_bits: string.string_to_bits(path), pad: 0 }
}
