// expect: default dyn ok 42
// No tu.mod anywhere: main and the undeclared `lib` package are dyn.
// Dyn code calls static packages through export facades, and reaches a
// non-export static fn only inside an unsafe block.

use fmt
use std
use os
use runtime
use lib

func main() {
    c = new lib.Counter(40)
    c.add(2)
    if c.get() != 42 {
        os.die("counter expected 42")
    }
    if lib.twice(21) != 42 {
        os.die("twice expected 42")
    }
    xs = [1, "two", 3]
    if std.len(xs) != 3 {
        os.die("len expected 3")
    }
    m = {"k": c.get()}
    if m["k"] != 42 {
        os.die("map expected 42")
    }
    hostos = -1
    unsafe {
        hostos = int(runtime.host_os())
    }
    if hostos < 0 {
        os.die("host_os expected >= 0")
    }
    fmt.printf("default dyn ok %d\n", m["k"])
}
