// RFC-110: static main calling staticdemo export facade, bare fn, and inherited sub.mul.

use fmt
use os
use staticdemo
use staticdemo.sub

fn main() {
    v = staticdemo.addDyn(2, 3)
    if v != 5 {
        os.die("addDyn expected 5")
    }

    b = staticdemo.addBridge()
    if b != 42 {
        os.die("addBridge expected 42")
    }

    n<i32> = staticdemo.add(4, 5)
    if n != 9 {
        os.die("add expected 9")
    }

    u<i32> = staticdemo.allow_dyn_in_unsafe()
    if u != 1 {
        os.die("allow_dyn_in_unsafe expected 1")
    }

    m<i32> = sub.mul(3, 4)
    if m != 12 {
        os.die("mul expected 12")
    }

    fmt.println("ok")
}
