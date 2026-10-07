use staticfix

// Dyn calling unexported static fn outside unsafe must fail.
export func bad() {
    return staticfix.add(1, 2)
}
