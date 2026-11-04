// expect: ok
// Dyn main calls the mixed suite freely (mixed performs no pkgmode checks).

use fmt
use os
use suite

func main() {
    v = suite.three()
    if v != 3 {
        os.die("three expected 3")
    }
    fmt.println("ok")
}
