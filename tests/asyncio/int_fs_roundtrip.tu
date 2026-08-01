// Integration tests for asyncio.fs (tasks 16.5 / 16.16 / 16.17 / 16.18).
// Sync fs_* factories return leaf futures; await inline via factory().await.
// Paths are string.String (Pillar B / TODO-8 debt cleanup).

use fmt
use os
use io
use string
use std
use asyncio.runtime as rt
use asyncio.fs as afs

fn str_buf(s<string.String>) io.Buf {
    sp<i8*> = string.cstr(s)
    slen<i32> = std.strlen(sp)
    b<io.Buf> = io.NewBuf(slen)
    io.buf_memcpy_in(b, sp, slen.(u64))
    return b
}

fn buf_equals(buf<io.Buf>, expect<string.String>) i32 {
    ep<i8*> = string.cstr(expect)
    elen_i<i32> = std.strlen(ep)
    elen<u64> = elen_i.(u64)
    if io.buf_len(buf) != elen return 0
    a<u8*> = io.buf_ptr(buf)
    b<u8*> = ep
    i<u64> = 0
    while i < io.buf_len(buf) {
        if a[i] != b[i] return 0
        i += 1
    }
    return 1
}

async fs_roundtrip_body() {
    path<string.String> = string.S(*"/tmp/asyncio_fs_rt.txt")
    msg<string.String>  = string.S(*"hello fs roundtrip")
    data<io.Buf> = str_buf(msg)
    ok<i32> = io.Ok

    werr<i32> = afs.fs_write(path, data).await
    if werr != ok return werr
    rerr<i32>, buf<io.Buf> = afs.fs_read(path).await
    if rerr != ok return rerr
    if buf_equals(buf, msg) == 0 {
        bad<i32> = io.OtherParse
        return bad
    }
    return afs.fs_remove_file(path).await
}

async fs_create_remove_dir_body() {
    root<string.String> = string.S(*"/tmp/asyncio_fs_dir")
    nested<string.String> = string.S(*"/tmp/asyncio_fs_dir/a/b")
    ok<i32> = io.Ok

    cerr<i32> = afs.fs_create_dir_all(nested).await
    if cerr != ok return cerr

    e1err<i32>, exists1<i32> = afs.fs_try_exists(nested).await
    if e1err != ok return e1err
    if exists1 == 0 {
        bad<i32> = io.OtherParse
        return bad
    }

    rerr<i32> = afs.fs_remove_dir_all(root).await
    if rerr != ok return rerr

    e2err<i32>, exists2<i32> = afs.fs_try_exists(root).await
    if e2err != ok return e2err
    if exists2 != 0 {
        bad2<i32> = io.OtherParse
        return bad2
    }

    return ok
}

async fs_metadata_rename_body() {
    src<string.String> = string.S(*"/tmp/asyncio_fs_meta.txt")
    dst<string.String> = string.S(*"/tmp/asyncio_fs_meta_renamed.txt")
    msg<string.String> = string.S(*"0123456789")
    data<io.Buf> = str_buf(msg)
    ok<i32> = io.Ok

    werr<i32> = afs.fs_write(src, data).await
    if werr != ok return werr

    merr<i32>, meta<afs.Metadata> = afs.fs_metadata(src).await
    if merr != ok return merr
    mlen<u64> = afs.metadata_len(meta)
    elen_u<u64> = std.strlen(string.cstr(msg))
    if mlen != elen_u {
        bad<i32> = io.OtherParse
        return bad
    }

    rnerr<i32> = afs.fs_rename(src, dst).await
    if rnerr != ok return rnerr

    e1err<i32>, has_old<i32> = afs.fs_try_exists(src).await
    if e1err != ok return e1err
    if has_old != 0 {
        bad2<i32> = io.OtherParse
        return bad2
    }

    e2err<i32>, has_new<i32> = afs.fs_try_exists(dst).await
    if e2err != ok return e2err
    if has_new == 0 {
        bad3<i32> = io.OtherParse
        return bad3
    }

    return afs.fs_remove_file(dst).await
}

async fs_read_dir_body() {
    dir<string.String> = string.S(*"/tmp/asyncio_fs_rd")
    ok<i32> = io.Ok

    cerr<i32> = afs.fs_create_dir_all(dir).await
    if cerr != ok return cerr

    p1<string.String> = string.S(*"/tmp/asyncio_fs_rd/f1")
    p2<string.String> = string.S(*"/tmp/asyncio_fs_rd/f2")
    p3<string.String> = string.S(*"/tmp/asyncio_fs_rd/f3")
    d1<io.Buf> = str_buf(string.S(*"a"))
    d2<io.Buf> = str_buf(string.S(*"b"))
    d3<io.Buf> = str_buf(string.S(*"c"))
    werr1<i32> = afs.fs_write(p1, d1).await
    if werr1 != ok return werr1
    werr2<i32> = afs.fs_write(p2, d2).await
    if werr2 != ok return werr2
    werr3<i32> = afs.fs_write(p3, d3).await
    if werr3 != ok return werr3

    rderr<i32>, rd<afs.ReadDir> = afs.fs_read_dir(dir).await
    if rderr != ok return rderr

    count<i32> = 0
    loop {
        nerr<i32>, name<string.String> = afs.fs_next_entry(rd).await
        if nerr != ok {
            afs.read_dir_close(rd)
            return nerr
        }
        if name == null break
        count += 1
    }
    afs.read_dir_close(rd)
    if count != 3 {
        bad<i32> = io.OtherParse
        return bad
    }

    return afs.fs_remove_dir_all(dir).await
}

fn int_fs_roundtrip(){
    fmt.println("int_fs_roundtrip test")

    b1<rt.Builder> = rt.Builder::new_current_thread()
    b1 = b1.enable_all()
    e1<i32>, r1<i64> = rt.builder_block_on(b1, fs_roundtrip_body(), 0)
    if e1 != 0 os.die("block_on failed")
    ri1<i32> = 0
    ri1 = r1
    if ri1 != io.Ok {
        fmt.println("fs_roundtrip failed")
        fmt.println(int(ri1))
        os.exit(1)
    }
    fmt.println("  fs_roundtrip passed")

    b2<rt.Builder> = rt.Builder::new_current_thread()
    b2 = b2.enable_all()
    e2<i32>, r2<i64> = rt.builder_block_on(b2, fs_create_remove_dir_body(), 0)
    if e2 != 0 os.die("block_on failed")
    ri2<i32> = 0
    ri2 = r2
    if ri2 != io.Ok {
        fmt.println("fs_create_remove_dir failed")
        fmt.println(int(ri2))
        os.exit(1)
    }
    fmt.println("  fs_create_remove_dir passed")

    b3<rt.Builder> = rt.Builder::new_current_thread()
    b3 = b3.enable_all()
    e3<i32>, r3<i64> = rt.builder_block_on(b3, fs_metadata_rename_body(), 0)
    if e3 != 0 os.die("block_on failed")
    ri3<i32> = 0
    ri3 = r3
    if ri3 != io.Ok {
        fmt.println("fs_metadata_rename failed")
        fmt.println(int(ri3))
        os.exit(1)
    }
    fmt.println("  fs_metadata_rename passed")

    b4<rt.Builder> = rt.Builder::new_current_thread()
    b4 = b4.enable_all()
    e4<i32>, r4<i64> = rt.builder_block_on(b4, fs_read_dir_body(), 0)
    if e4 != 0 os.die("block_on failed")
    ri4<i32> = 0
    ri4 = r4
    if ri4 != io.Ok {
        fmt.println("fs_read_dir failed")
        fmt.println(int(ri4))
        os.exit(1)
    }
    fmt.println("  fs_read_dir passed")

    fmt.println("int_fs_roundtrip passed")
}

// Same four bodies under multi_thread + enable_all (blocking pool + workers).
fn run_fs_mt(name<i8*>, body) {
    b<rt.Builder> = rt.Builder::new_multi_thread()
    b = b.worker_threads(4)
    b = b.enable_all()
    e<i32>, r<i64> = rt.builder_block_on(b, body, 0)
    if e != 0 os.dief("mt block_on failed: %d", e)
    ri<i32> = 0
    ri = r
    if ri != io.Ok {
        fmt.println(string.new(name))
        fmt.println("mt body failed")
        fmt.println(int(ri))
        os.exit(1)
    }
    fmt.println(string.new(name))
}

fn int_fs_roundtrip_mt(){
    fmt.println("int_fs_roundtrip_mt test")
    run_fs_mt("  mt fs_roundtrip passed", fs_roundtrip_body())
    run_fs_mt("  mt fs_create_remove_dir passed", fs_create_remove_dir_body())
    run_fs_mt("  mt fs_metadata_rename passed", fs_metadata_rename_body())
    run_fs_mt("  mt fs_read_dir passed", fs_read_dir_body())
    // Second MT runtime after fs work must stay clean.
    run_fs_mt("  mt fs_roundtrip again passed", fs_roundtrip_body())
    fmt.println("int_fs_roundtrip_mt passed")
}

fn main(){
    int_fs_roundtrip()
    int_fs_roundtrip_mt()
}
