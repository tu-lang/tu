// expect: pkgmode: fn definition not allowed in dyn package
// No tu.mod: main is dyn, so a package-level static fn (other than main) is rejected.

use fmt

fn helper() i32 {
    return 1
}

func main() {
    fmt.println(int(helper()))
}
