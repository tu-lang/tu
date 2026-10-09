// expect: default static sublib ok 7
// No tu.mod above main: main is dyn, while the `fix` subpackage declares its own
// static manifest (nearest manifest wins). Dyn code reaches it via export only.

use fmt
use os
use fix

func main() {
    s = fix.make_sum(3, 4)
    if s != 7 {
        os.dief("make_sum expected 7, got %d", s)
    }
    fmt.printf("default static sublib ok %d\n", s)
}
