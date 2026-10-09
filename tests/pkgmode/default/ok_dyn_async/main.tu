// expect: default dyn async ok 18
// No tu.mod anywhere: async class members, package-level async and .await
// are all usable from default-dyn code; the future is driven to completion
// by the static runtime.block inside an unsafe block.

use fmt
use os
use runtime
use lib

// Dynamic accumulator driven by async member calls.
class Acc {
    total
    func init() {
        this.total = 0
    }
}

// Awaits a package-level async in another undeclared package, a sibling
// async member and a package-level async in this package.
async Acc::run(n) {
    a = lib.add_later(n, 2).await
    b = this.step(3).await
    c = double_it(b).await
    this.total = a + b + c - 6
    return this.total
}

// Async member with no awaits.
async Acc::step(k) {
    return k * 2
}

// Package-level async without awaits.
async double_it(x) {
    return x * 2
}

func main() {
    acc = new Acc()
    r = 0
    unsafe {
        r = runtime.block(acc.run(4))
    }
    if r != 18 {
        os.dief("run expected 18, got %d", r)
    }
    if acc.total != 18 {
        os.die("total expected 18")
    }
    fmt.printf("default dyn async ok %d\n", r)
}
