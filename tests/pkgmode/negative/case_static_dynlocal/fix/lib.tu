// Untyped local in static fn must be rejected outside unsafe.
fn bad() i32 {
    a = 1
    return 0
}
