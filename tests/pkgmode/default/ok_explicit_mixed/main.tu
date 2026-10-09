// expect: explicit mixed ok 7
// An explicit `mode mixed` manifest is still accepted (test-suite opt-in):
// static and dynamic definitions coexist without pkgmode checks.

use fmt
use os

mem Pair {
    i32 a, b
}

fn sum(p<Pair>) i32 {
    return p.a + p.b
}

func main() {
    p<Pair> = new Pair { a: 3, b: 4 }
    n<i32> = sum(p)
    if n != 7 {
        os.die("sum expected 7")
    }
    fmt.printf("explicit mixed ok %d\n", int(n))
}
