// expect: pkgmode: static type annotation not allowed in dynamic context outside unsafe
// No tu.mod: main is dyn, so a typed local outside unsafe is rejected.

use fmt

func main() {
    v<i32> = 1
    fmt.println(int(v))
}
