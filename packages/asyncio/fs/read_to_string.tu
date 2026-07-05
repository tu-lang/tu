// fs_read_to_string (tokio::fs::read_to_string): read a file and validate the
// bytes are UTF-8 before handing back a String.

use io
use string

// Minimal UTF-8 well-formedness check: verifies leading-byte / continuation-byte
// structure (not full Unicode scalar-range rejection). Returns false on any
// truncated or malformed sequence.
fn is_valid_utf8(buf<io.Buf>) bool {
    p<u8*> = buf.ptr()
    len<u64> = buf.len()
    i<u64> = 0
    while i < len {
        c<u8> = p[i]
        if c < 128 {
            i += 1
            continue
        }
        cont<u64> = 0
        if (c.(i32) & 224) == 192 {
            cont = 1
        } else if (c.(i32) & 240) == 224 {
            cont = 2
        } else if (c.(i32) & 248) == 240 {
            cont = 3
        } else {
            return false
        }
        if i + cont >= len return false
        j<u64> = 1
        while j <= cont {
            if (p[i + j].(i32) & 192) != 128 return false
            j += 1
        }
        i += cont + 1
    }
    return true
}

// Read `path` and return its contents as a String. Returns io.InvalidData when
// the bytes are not valid UTF-8, or the underlying read error.
async fs_read_to_string(path<string.String>) i32, string.String {
    rerr<i32>, buf<io.Buf> = fs_read(path).await
    if rerr != io.Ok return rerr, null
    if is_valid_utf8(buf) == false return io.InvalidData, null
    s<string.String> = new string.String { inner: string.newlen(buf.ptr(), buf.len()) }
    return io.Ok, s
}
