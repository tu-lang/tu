// expect: pkgmode: static symbol 'host_os' not exported from static package 'runtime'
// No tu.mod: the dyn `lib` package calls a non-export static fn outside unsafe.

use lib

func main() {
    lib.probe()
}
