// Static package fixture for RFC-110 pkgmode tests.

fn add(a<i32>, b<i32>) i32 {
    return a + b
}

// Dynamic facade: pure dyn body (no static touch).
export func addDyn(a, b) {
    return a + b
}

// Scheme A: export body may bridge to static without `unsafe`.
export func addBridge() {
    x<i32> = 40
    y<i32> = 2
    return int(add(x, y))
}

mem Counter {
    i32 n
}

Counter::inc() {
    this.n += 1
}

Counter::get() i32 {
    return this.n
}

func init() {}

// Untyped local allowed inside unsafe in static fn.
// Note: `return int(a)` from inside unsafe { } currently mishandles the static
// return path; compare dyn then assign typed local (same ModeCheck coverage).
fn allow_dyn_in_unsafe() i32 {
    r<i32> = 0
    unsafe {
        a = 1
        if a == 1 {
            r = 1
        }
    }
    return r
}
