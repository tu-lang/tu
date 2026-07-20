// Formal tests for library/io Buf cross-pkg bridges:
// buf_len / buf_ptr / buf_memcpy_in / buf_slice / buf_with_len.

use fmt
use os
use std
use io

fn test_buf_bridges(){
    fmt.println("test io buf bridges")
    b<io.Buf> = io.NewBuf(8)
    if io.buf_len(b) != 8 os.die("buf_len != 8")
    p<i8*> = io.buf_ptr(b)
    if p == null os.die("buf_ptr null")

    src<i8*> = "abcdefg"
    io.buf_memcpy_in(b, src, 7)
    if p[0] != 'a' os.die("memcpy[0]")
    if p[6] != 'g' os.die("memcpy[6]")

    mid<io.Buf> = io.buf_slice(b, 2, 3)
    if io.buf_len(mid) != 3 os.die("slice len")
    mp<i8*> = io.buf_ptr(mid)
    if mp[0] != 'c' os.die("slice[0]")
    if mp[2] != 'e' os.die("slice[2]")

    short_b<io.Buf> = io.buf_with_len(b, 4)
    if io.buf_len(short_b) != 4 os.die("with_len")
    if io.buf_ptr(short_b) != p os.die("with_len ptr")

    fmt.println("test io buf bridges success")
}

fn main(){
    test_buf_bridges()
}
