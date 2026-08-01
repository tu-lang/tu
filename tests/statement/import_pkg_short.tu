// Package short-name vs library: nested `*.io` can bare `use io` and keep local globals.
use fmt
use os
use shpkg.io as dio

fn main() {
    w<dio.Writer> = dio.make()
    n<i32> = w.write_n()
    if n != 7 {
        os.die("import_pkg_short: expected 7")
    }
    fmt.println("import_pkg_short done")
}
