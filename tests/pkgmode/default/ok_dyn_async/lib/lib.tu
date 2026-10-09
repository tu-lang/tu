// Undeclared package (no tu.mod): defaults to dyn, package-level async is legal.

// Package-level async without awaits.
async add_later(x, y) {
    return x + y
}
