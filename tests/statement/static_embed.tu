// Static EmbedFS mem path (RFC-107).
use fmt
use os
use std

fn main() {
	fs<EmbedFS> = embed("embed_testdata/static")
	err<i32>, p<i8*>, n<u64> = fs.read("embed_testdata/static/a.txt")
	if err != 0 {
		os.dief("EmbedFS.read err=%d", int(err))
	}
	if n != 5 {
		os.dief("EmbedFS.read n=%d", int(n))
	}
	// compare bytes
	if p[0] != 'a' || p[1] != 'l' || p[2] != 'p' || p[3] != 'h' || p[4] != 'a' {
		os.dief("EmbedFS.read bytes mismatch")
	}
	if fs.has("embed_testdata/static/a.txt") == 0 {
		os.dief("EmbedFS.has miss")
	}
	if fs.has("nope") != 0 {
		os.dief("EmbedFS.has false positive")
	}
	c<i32> = fs.count()
	if c < 2 {
		os.dief("EmbedFS.count=%d", int(c))
	}
	fmt.println("embed static ok")
}
