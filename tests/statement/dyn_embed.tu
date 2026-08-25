// Dynamic embed: untyped string + FS object (RFC-107).
use fmt
use os
use std

fn main() {
	test_string()
	test_fs_obj()
	fmt.println("embed dyn ok")
}

fn test_string() {
	s = embed("embed_testdata/hello.txt")
	if s != "hello embed\n" {
		os.dief("embed string want hello embed\\n got %s", s)
	}
}

fn test_fs_obj() {
	fs = embed("embed_testdata/static")
	err, body = fs.read("embed_testdata/static/a.txt")
	if err != 0 {
		os.dief("fs.read a err=%d", err)
	}
	if body != "alpha" {
		os.dief("fs.read a body=%s", body)
	}
	err2, body2 = fs.read("embed_testdata/static/b.txt")
	if err2 != 0 || body2 != "beta" {
		os.dief("fs.read b")
	}
	lerr, names = fs.list("embed_testdata/static")
	if lerr != 0 {
		os.dief("fs.list err=%d", lerr)
	}
	if std.len(names) < 2 {
		os.dief("fs.list len=%d", std.len(names))
	}
}
