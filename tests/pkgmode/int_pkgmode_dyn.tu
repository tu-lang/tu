// RFC-110: static main exercising dyndemo via unsafe bridge and cross-package export.

use fmt
use os
use dyndemo

fn main() {
    a = dyndemo.hello(1)
    if a != 2 {
        os.die("hello expected 2")
    }

    b = dyndemo.fast()
    if b != 30 {
        os.die("fast expected 30")
    }

    box = new dyndemo.Box(7)
    if box.get() != 7 {
        os.die("Box.get expected 7")
    }

    fmt.println("ok")
}
