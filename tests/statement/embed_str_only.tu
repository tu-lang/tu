use fmt
use os
fn main() {
	s = embed("embed_testdata/hello.txt")
	fmt.println(s)
	if s != "hello embed\n" {
		os.die("bad")
	}
	fmt.println("ok")
}
