use fmt
use os
use std
fn main() {
	fs = embed("embed_testdata/static")
	fmt.println("boxed")
	err, body = fs.read("embed_testdata/static/a.txt")
	fmt.println("err", err)
	fmt.println("body", body)
	if err != 0 {
		os.dief("read err %d", err)
	}
	if body != "alpha" {
		os.dief("body %s", body)
	}
	fmt.println("fs ok")
}
