// Integration tests for asyncio.fs (tasks 16.5 / 16.16 / 16.17 / 16.18).
// Await typed leaf futures from sync factories (tcp ConnectFut pattern).
// Paths cross into asyncio.fs as u64 bits (string.string_to_bits).

use fmt
use os
use io
use string
use std
use runtime
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
    pb<u64> = string.string_to_bits(path)
    ok<i32> = io.Ok

    wfut<afs.WriteFut> = afs.fs_write(pb, io.buf_to_bits(data))
    werr<i32> = wfut.await
    if werr != ok return werr
    pb = string.string_to_bits(path)
    rfut<afs.ReadFut> = afs.fs_read(pb)
    rerr<i32>, buf<io.Buf> = rfut.await
    if rerr != ok return rerr
    if buf_equals(buf, msg) == 0 {
        bad<i32> = io.OtherParse
        return bad
    }
    pb = string.string_to_bits(path)
    rmfut<afs.RemoveFileFut> = afs.fs_remove_file(pb)
    rmerr<i32> = rmfut.await
    return rmerr
}

async fs_create_remove_dir_body() {
    root<string.String> = string.S(*"/tmp/asyncio_fs_dir")
    nested<string.String> = string.S(*"/tmp/asyncio_fs_dir/a/b")
    rb<u64> = string.string_to_bits(root)
    nb<u64> = string.string_to_bits(nested)
    ok<i32> = io.Ok

    cfut<afs.CreateDirAllFut> = afs.fs_create_dir_all(nb)
    cerr<i32> = cfut.await
    if cerr != ok return cerr

    e1fut<afs.TryExistsFut> = afs.fs_try_exists(nb)
    e1err<i32>, exists1<i32> = e1fut.await
    if e1err != ok return e1err
    if exists1 == 0 {
        bad<i32> = io.OtherParse
        return bad
    }

    rdfut<afs.RemoveDirAllFut> = afs.fs_remove_dir_all(rb)
    rerr<i32> = rdfut.await
    if rerr != ok return rerr

    rb = string.string_to_bits(root)
    e2fut<afs.TryExistsFut> = afs.fs_try_exists(rb)
    e2err<i32>, exists2<i32> = e2fut.await
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
    sb<u64> = string.string_to_bits(src)
    db<u64> = string.string_to_bits(dst)
    ok<i32> = io.Ok

    wfut<afs.WriteFut> = afs.fs_write(sb, io.buf_to_bits(data))
    werr<i32> = wfut.await
    if werr != ok return werr

    sb = string.string_to_bits(src)
    mfut<afs.MetadataFut> = afs.fs_metadata(sb)
    merr<i32>, meta<afs.Metadata> = mfut.await
    if merr != ok return merr
    mlen<u64> = afs.metadata_len(meta)
    msg_bits<u64> = string.string_to_bits(msg)
    msg_c<i8*> = string.cstr_from_bits(msg_bits)
    elen_u<u64> = std.strlen(msg_c)
    if mlen != elen_u {
        bad<i32> = io.OtherParse
        return bad
    }

    sb = string.string_to_bits(src)
    db = string.string_to_bits(dst)
    rnfut<afs.RenameFut> = afs.fs_rename(sb, db)
    rnerr<i32> = rnfut.await
    if rnerr != ok return rnerr

    sb = string.string_to_bits(src)
    e1fut<afs.TryExistsFut> = afs.fs_try_exists(sb)
    e1err<i32>, has_old<i32> = e1fut.await
    if e1err != ok return e1err
    if has_old != 0 {
        bad2<i32> = io.OtherParse
        return bad2
    }

    db = string.string_to_bits(dst)
    e2fut<afs.TryExistsFut> = afs.fs_try_exists(db)
    e2err<i32>, has_new<i32> = e2fut.await
    if e2err != ok return e2err
    if has_new == 0 {
        bad3<i32> = io.OtherParse
        return bad3
    }

    db = string.string_to_bits(dst)
    rmfut<afs.RemoveFileFut> = afs.fs_remove_file(db)
    return rmfut.await
}

async fs_read_dir_body() {
    dir<string.String> = string.S(*"/tmp/asyncio_fs_rd")
    dbits<u64> = string.string_to_bits(dir)
    ok<i32> = io.Ok

    cfut<afs.CreateDirAllFut> = afs.fs_create_dir_all(dbits)
    cerr<i32> = cfut.await
    if cerr != ok return cerr

    p1<string.String> = string.S(*"/tmp/asyncio_fs_rd/f1")
    p2<string.String> = string.S(*"/tmp/asyncio_fs_rd/f2")
    p3<string.String> = string.S(*"/tmp/asyncio_fs_rd/f3")
    d1<io.Buf> = str_buf(string.S(*"a"))
    d2<io.Buf> = str_buf(string.S(*"b"))
    d3<io.Buf> = str_buf(string.S(*"c"))
    pb1<u64> = string.string_to_bits(p1)
    pb2<u64> = string.string_to_bits(p2)
    pb3<u64> = string.string_to_bits(p3)
    w1<afs.WriteFut> = afs.fs_write(pb1, io.buf_to_bits(d1))
    werr1<i32> = w1.await
    if werr1 != ok return werr1
    w2<afs.WriteFut> = afs.fs_write(pb2, io.buf_to_bits(d2))
    werr2<i32> = w2.await
    if werr2 != ok return werr2
    w3<afs.WriteFut> = afs.fs_write(pb3, io.buf_to_bits(d3))
    werr3<i32> = w3.await
    if werr3 != ok return werr3

    dbits = string.string_to_bits(dir)
    rdfut<afs.ReadDirFut> = afs.fs_read_dir(dbits)
    rderr<i32>, rd<afs.ReadDir> = rdfut.await
    if rderr != ok return rderr

    count<i32> = 0
    zero_bits<u64> = 0
    loop {
        nfut<afs.NextEntryFut> = afs.fs_next_entry(rd)
        nerr<i32>, name_bits<u64> = nfut.await
        if nerr != ok {
            afs.read_dir_close(rd)
            return nerr
        }
        if name_bits == zero_bits break
        count += 1
    }
    afs.read_dir_close(rd)
    if count != 3 {
        bad<i32> = io.OtherParse
        return bad
    }

    dbits = string.string_to_bits(dir)
    rmall<afs.RemoveDirAllFut> = afs.fs_remove_dir_all(dbits)
    return rmall.await
}

fn int_fs_roundtrip(){
    fmt.println("int_fs_roundtrip test")

    b1<rt.Builder> = rt.Builder::new_current_thread()
    b1 = b1.enable_all()
    body1<runtime.Future> = fs_roundtrip_body()
    fut1<u64> = 0
    fut1 = body1
    e1<i32>, r1<i64> = rt.builder_block_on(b1, fut1, 0)
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
    body2<runtime.Future> = fs_create_remove_dir_body()
    fut2<u64> = 0
    fut2 = body2
    e2<i32>, r2<i64> = rt.builder_block_on(b2, fut2, 0)
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
    body3<runtime.Future> = fs_metadata_rename_body()
    fut3<u64> = 0
    fut3 = body3
    e3<i32>, r3<i64> = rt.builder_block_on(b3, fut3, 0)
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
    body4<runtime.Future> = fs_read_dir_body()
    fut4<u64> = 0
    fut4 = body4
    e4<i32>, r4<i64> = rt.builder_block_on(b4, fut4, 0)
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

fn main(){
    int_fs_roundtrip()
}
