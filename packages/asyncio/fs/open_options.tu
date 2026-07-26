// File open options. Collects the read/write/create
// flags a caller wants, then lowers them to a Linux open(2) flag word. The
// access + creation combinations are validated before open.

use std
use io

// Requested open behaviour. Booleans are stored as i32 (0/1); mode is the
// permission bits applied when the file is created.
mem OpenOptions {
    i32 read
    i32 write
    i32 append
    i32 truncate
    i32 create
    i32 create_new
    u32 mode        // permission bits for newly created files (default 0o666)
}

// Fresh options with everything off and mode = 0o666.
const OpenOptions::new() OpenOptions {
    o<OpenOptions> = new OpenOptions
    o.read       = 0
    o.write      = 0
    o.append     = 0
    o.truncate   = 0
    o.create     = 0
    o.create_new = 0
    o.mode       = 438
    return o
}

// Chained setters (return self so calls compose).
OpenOptions::read(on<i32>) OpenOptions {
    this.read = 0
    if on != 0 this.read = 1
    return this
}
OpenOptions::write(on<i32>) OpenOptions {
    this.write = 0
    if on != 0 this.write = 1
    return this
}
OpenOptions::append(on<i32>) OpenOptions {
    this.append = 0
    if on != 0 this.append = 1
    return this
}
OpenOptions::truncate(on<i32>) OpenOptions {
    this.truncate = 0
    if on != 0 this.truncate = 1
    return this
}
OpenOptions::create(on<i32>) OpenOptions {
    this.create = 0
    if on != 0 this.create = 1
    return this
}
OpenOptions::create_new(on<i32>) OpenOptions {
    this.create_new = 0
    if on != 0 this.create_new = 1
    return this
}
OpenOptions::mode(m<u32>) OpenOptions {
    this.mode = m
    return this
}

// Access-mode flags (O_RDONLY / O_WRONLY / O_RDWR, plus O_APPEND). append
// implies write. Returns (io.InvalidInput, 0) when no access is requested.
OpenOptions::access_mode() i32, i64 {
    if this.append != 0 {
        if this.read != 0 return io.Ok, std.O_RDWR | std.O_APPEND
        return io.Ok, std.O_WRONLY | std.O_APPEND
    }
    if this.read != 0 && this.write != 0 return io.Ok, std.O_RDWR
    if this.write != 0 return io.Ok, std.O_WRONLY
    if this.read != 0 return io.Ok, std.O_RDONLY
    return io.InvalidInput, 0
}

// Creation flags (O_CREAT / O_TRUNC / O_EXCL). Requires write/append access to
// set any creation flag; create_new implies O_CREAT|O_EXCL and ignores
// truncate. Returns (io.InvalidInput, 0) on an illegal combination.
OpenOptions::creation_mode() i32, i64 {
    if this.write == 0 && this.append == 0 {
        if this.truncate != 0 || this.create != 0 || this.create_new != 0 {
            return io.InvalidInput, 0
        }
    }
    if this.create_new != 0 return io.Ok, std.O_CREAT | std.O_EXCL
    if this.create != 0 && this.truncate != 0 return io.Ok, std.O_CREAT | std.O_TRUNC
    if this.create != 0 return io.Ok, std.O_CREAT
    if this.truncate != 0 return io.Ok, std.O_TRUNC
    return io.Ok, 0
}

// Lower the options to a full open(2) flag word. Returns (io.Ok, flags) or an
// error code with 0 flags for an invalid combination.
OpenOptions::to_flags() i32, i64 {
    aerr<i32>, acc<i64> = this.access_mode()
    if aerr != io.Ok return aerr, 0
    cerr<i32>, cre<i64> = this.creation_mode()
    if cerr != io.Ok return cerr, 0
    return io.Ok, acc | cre
}
