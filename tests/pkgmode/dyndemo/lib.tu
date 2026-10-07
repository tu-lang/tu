// Dyn package fixture: bare func (dyn has no export) + unsafe bridge to static fn.

use staticdemo

func hello(x) {
    return staticdemo.addDyn(x, 1)
}

// Cross-mode call to unexported static fn; typed locals stay inside unsafe.
unsafe func fast() {
    n<i32> = staticdemo.add(10, 20)
    return int(n)
}

class Box {
    v
    func init(x) {
        this.v = x
    }
    func get() {
        return this.v
    }
}
