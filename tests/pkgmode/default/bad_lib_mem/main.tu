// expect: pkgmode: mem definition not allowed in dyn package
// No tu.mod: the imported `lib` package is dyn too, so its mem definition is rejected.

use lib

func main() {
    lib.ping()
}
