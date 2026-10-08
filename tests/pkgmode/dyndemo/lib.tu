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
    // Sync method handing out a future; awaited via the runtime await check.
    func later(n) {
        return this.addLater(n)
    }
}

// Async member awaited through a dynamic receiver.
async Box::addLater(n) {
    return this.v + n
}

// Plain func returning a future.
func mkfut(b, n) {
    return b.addLater(n)
}

// .await inside a dyn package: dynamic var, sync member returning a future,
// async member on a dynamic receiver, and a plain func returning a future.
// Each form appears twice with different receivers / arguments.
async dynAwait(b, c) {
    f1 = b.later(1)
    f2 = c.later(2)
    v1 = f1.await
    v2 = f2.await
    s1 = b.later(3).await
    s2 = c.later(4).await + 1
    a1 = b.addLater(5).await
    a2 = c.addLater(6).await * 2
    p1 = mkfut(b, 7).await
    p2 = mkfut(c, 8).await - b.later(0).await
    return v1 + v2 + s1 + s2 + a1 + a2 + p1 + p2
}
