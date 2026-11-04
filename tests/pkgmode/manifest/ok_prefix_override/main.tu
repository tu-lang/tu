// expect: ok
// Dyn main: peer static subtree "a" via its export facade (plain call), dyn
// leaf "a/b" (longest prefix beats "a") natively. This proves both prefixes
// resolve independently from one project manifest.

use fmt
use os
use a
use a.b

func main() {
    x = a.oneDyn()
    if x != 1 {
        os.die("oneDyn expected 1")
    }
    y = b.two()
    if y != 2 {
        os.die("two expected 2")
    }
    fmt.println("ok")
}
