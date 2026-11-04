// expect: ok
// Dyn main calls the static lib through its export facade (plain call allowed).

use fmt
use os
use lib

func main() {
    v = lib.addBridge()
    if v != 42 {
        os.die("addBridge expected 42")
    }
    fmt.println("ok")
}
