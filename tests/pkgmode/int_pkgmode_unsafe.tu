// RFC-110: static main may use unsafe { } blocks; statement itself is legal.

use fmt
use os
use staticdemo

fn main() {
    r = 0
    unsafe {
        n<i32> = staticdemo.add(40, 2)
        r = int(n)
    }
    if r != 42 {
        os.die("unsafe block expected 42")
    }
    fmt.println("ok")
}
