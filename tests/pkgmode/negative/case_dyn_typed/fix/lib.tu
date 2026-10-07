// Typed local in dyn outside unsafe must fail.
func bad() {
    v<i32> = 1
    return v
}
