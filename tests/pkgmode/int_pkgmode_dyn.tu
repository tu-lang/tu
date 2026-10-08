// RFC-110: static main exercising dyndemo via unsafe bridge and cross-package export.

use fmt
use os
use runtime
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

    // .await in a dyn package lowers to the runtime await check (compiler ABI)
    // and must not trip the cross-mode export rule.
    box2 = new dyndemo.Box(100)
    got = runtime.block(dyndemo.dynAwait(box, box2))
    if got != 564 {
        os.dief("dynAwait expected 564 got %d", got)
    }

    fmt.println("ok")
}
