// expect: pkgmode: static symbol 'sum_raw' not exported from static package 'fix'; call an export or use unsafe
// No tu.mod above main (dyn); `fix` declares static. Calling its non-export
// fn from dyn code outside unsafe must be rejected.

use fix

func main() {
    fix.sum_raw(null)
}
