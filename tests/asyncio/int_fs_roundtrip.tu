// Integration tests for asyncio.fs (tasks 16.5 / 16.16 / 16.17 / 16.18):
//   - roundtrip: write a file, read it back, bytes match, remove it
//   - create/remove dir: create_dir_all -> try_exists true -> remove_dir_all
//                        -> try_exists false
//   - metadata + rename: metadata size matches, rename moves the file
//   - read_dir: create dir + files, read_dir yields every entry
//
// fs syscalls are Linux-only and run inline (V1); validated on Linux CI, not
// the Windows host.

use fmt
use os
use io
use string
use std
use asyncio.runtime as rt
use asyncio.fs as afs

// Wrap a String's bytes as a borrowed io.Buf (no copy).
fn str_buf(s<string.String>) io.Buf {
    return new io.Buf { inner: s.str(), len: s.len().(u64) }
}

// Byte-compare a read buffer against expected string bytes.
fn buf_equals(buf<io.Buf>, expect<string.String>) bool {
    if buf.len() != expect.len().(u64) return false
    a<u8*> = buf.ptr()
    b<u8*> = expect.str()
    i<u64> = 0
    while i < buf.len() {
        if a[i] != b[i] return false
        i += 1
    }
    return true
}

// task 16.5: write then read a file and confirm the payload round-trips.
async fs_roundtrip_body() i32 {
    path<string.String> = string.S(*"/tmp/asyncio_fs_rt.txt")
    msg<string.String>  = string.S(*"hello fs roundtrip")

    werr<i32> = afs.fs_write(path, str_buf(msg)).await
    if werr != io.Ok return werr

    rerr<i32>, buf<io.Buf> = afs.fs_read(path).await
    if rerr != io.Ok return rerr
    if buf_equals(buf, msg) == false return io.OtherParse

    return afs.fs_remove_file(path).await
}

// task 16.16: create nested dirs, confirm existence, remove the tree, confirm
// it is gone.
async fs_create_remove_dir_body() i32 {
    root<string.String> = string.S(*"/tmp/asyncio_fs_dir")
    nested<string.String> = string.S(*"/tmp/asyncio_fs_dir/a/b")

    cerr<i32> = afs.fs_create_dir_all(nested).await
    if cerr != io.Ok return cerr

    e1err<i32>, exists1<bool> = afs.fs_try_exists(nested).await
    if e1err != io.Ok return e1err
    if exists1 == false return io.OtherParse

    rerr<i32> = afs.fs_remove_dir_all(root).await
    if rerr != io.Ok return rerr

    e2err<i32>, exists2<bool> = afs.fs_try_exists(root).await
    if e2err != io.Ok return e2err
    if exists2 return io.OtherParse

    return io.Ok
}

// task 16.17: metadata size matches the written bytes, and rename moves the
// file so the old path disappears and the new one appears.
async fs_metadata_rename_body() i32 {
    src<string.String> = string.S(*"/tmp/asyncio_fs_meta.txt")
    dst<string.String> = string.S(*"/tmp/asyncio_fs_meta_renamed.txt")
    msg<string.String> = string.S(*"0123456789")

    werr<i32> = afs.fs_write(src, str_buf(msg)).await
    if werr != io.Ok return werr

    merr<i32>, meta<afs.Metadata> = afs.fs_metadata(src).await
    if merr != io.Ok return merr
    if meta.len() != msg.len().(u64) return io.OtherParse

    rnerr<i32> = afs.fs_rename(src, dst).await
    if rnerr != io.Ok return rnerr

    e1err<i32>, has_old<bool> = afs.fs_try_exists(src).await
    if e1err != io.Ok return e1err
    if has_old return io.OtherParse

    e2err<i32>, has_new<bool> = afs.fs_try_exists(dst).await
    if e2err != io.Ok return e2err
    if has_new == false return io.OtherParse

    return afs.fs_remove_file(dst).await
}

// task 16.18: create a directory with three files, then read_dir and confirm
// all three entries are visited.
async fs_read_dir_body() i32 {
    dir<string.String> = string.S(*"/tmp/asyncio_fs_rd")

    cerr<i32> = afs.fs_create_dir_all(dir).await
    if cerr != io.Ok return cerr

    werr1<i32> = afs.fs_write(string.S(*"/tmp/asyncio_fs_rd/f1"), str_buf(string.S(*"a"))).await
    if werr1 != io.Ok return werr1
    werr2<i32> = afs.fs_write(string.S(*"/tmp/asyncio_fs_rd/f2"), str_buf(string.S(*"b"))).await
    if werr2 != io.Ok return werr2
    werr3<i32> = afs.fs_write(string.S(*"/tmp/asyncio_fs_rd/f3"), str_buf(string.S(*"c"))).await
    if werr3 != io.Ok return werr3

    rderr<i32>, rd<afs.ReadDir> = afs.fs_read_dir(dir).await
    if rderr != io.Ok return rderr

    count<i32> = 0
    loop {
        nerr<i32>, ent<afs.DirEntry> = rd.next_entry().await
        if nerr != io.Ok {
            rd.close()
            return nerr
        }
        if ent == null break
        count += 1
    }
    rd.close()
    if count != 3 return io.OtherParse

    return afs.fs_remove_dir_all(dir).await
}

// Drive future `body` to completion on `r`, aborting on any failure.
fn run_body(r<rt.Runtime>, name<i8*>, body) {
    rerr<i32>, result<i64> = r.block_on(body)
    if rerr != 0 os.dief("block_on failed: %d", rerr)
    if result.(i32) != io.Ok os.dief("fs body failed: %d", result.(i32))
    fmt.println(name)
}

fn int_fs_roundtrip(){
    fmt.println("int_fs_roundtrip test")

    b<rt.Builder> = rt.Builder::new_current_thread()
    b = b.enable_all()
    berr<i32>, r<rt.Runtime> = b.build()
    if berr != 0 os.dief("runtime build failed: %d", berr)

    run_body(r, "  fs_roundtrip passed", fs_roundtrip_body())
    run_body(r, "  fs_create_remove_dir passed", fs_create_remove_dir_body())
    run_body(r, "  fs_metadata_rename passed", fs_metadata_rename_body())
    run_body(r, "  fs_read_dir passed", fs_read_dir_body())

    r.shutdown_background()
    fmt.println("int_fs_roundtrip passed")
}

fn main(){
    int_fs_roundtrip()
}
