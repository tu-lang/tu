// Mixed: dyn string + static EmbedFS in one file.
use fmt
use os

fn main() {
	s = embed("embed_testdata/hello.txt")
	if s != "hello embed\n" {
		os.die("mixed string")
	}
	fs<EmbedFS> = embed("embed_testdata/static")
	err<i32>, p<i8*>, n<u64> = fs.read("embed_testdata/static/b.txt")
	if err != 0 {
		os.die("mixed fs read")
	}
	if n != 4 {
		os.dief("mixed fs n=%d", int(n))
	}
	if p[0] != 'b' || p[1] != 'e' || p[2] != 't' || p[3] != 'a' {
		os.die("mixed fs bytes")
	}
	fmt.println("embed mixed ok")
}
