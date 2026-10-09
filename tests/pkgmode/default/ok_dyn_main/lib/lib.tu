// Undeclared package (no tu.mod): defaults to dyn, so bare func/class are legal.

func twice(x) {
    return x * 2
}

// Dynamic counter object.
class Counter {
    n
    func init(start) {
        this.n = start
    }
    func add(k) {
        this.n += k
    }
    func get() {
        return this.n
    }
}
