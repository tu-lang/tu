// Await erased runtime.Future and sync factories returning mem:async leaves.
// Assign factory then poll.

use fmt
use os
use runtime

mem PollFuture: async {
    i32 count
}

PollFuture::poll(ctx){
    this.count += 1
    if this.count < 2 {
        return runtime.PollPending
    }
    return runtime.PollReady, this.count
}

// Sync factory returning erased Future (asyncio.time.sleep style).
fn make_fut() runtime.Future {
    f<PollFuture> = new PollFuture{}
    fut<runtime.Future> = f
    return fut
}

// Concrete async leaf (TcpStream::connect style).
mem LeafFut: async {
    i32 val
}
LeafFut::poll(ctx){
    return runtime.PollReady, this.val
}

mem Holder {
    i32 pad
}
const Holder::make() LeafFut {
    f<LeafFut> = new LeafFut
    f.val = 9
    return f
}

async test_var_await() {
    f1<runtime.Future> = make_fut()
    c1<i32> = f1.await
    if c1 != 2 {
        os.die("var Future.await count should be 2")
    }
    f2<runtime.Future> = make_fut()
    c2<i32> = f2.await
    if c2 != 2 {
        os.die("second var Future.await count should be 2")
    }
    return c1 + c2
}

async test_factory_await() {
    c1<i32> = make_fut().await
    if c1 != 2 {
        os.die("factory().await count should be 2")
    }
    c2<i32> = make_fut().await
    if c2 != 2 {
        os.die("second factory().await count should be 2")
    }
    return c1 + c2
}

async test_mixed_await() {
    f1<runtime.Future> = make_fut()
    c1<i32> = f1.await
    if c1 != 2 {
        return -1
    }
    c2<i32> = make_fut().await
    if c2 != 2 {
        return -2
    }
    return c1 + c2
}

async test_leaf_static_await() {
    v<i32> = Holder::make().await
    if v != 9 {
        os.die("Holder::make().await should be 9")
    }
    return v
}

fn run_one(name, body_f<runtime.Future>, expect<i32>) {
    r = runtime.block(body_f)
    if r != expect {
        os.dief("%s: got %d expect %d", name, int(r), int(expect))
    }
    fmt.println(name)
    fmt.println("passed")
}

fn main() {
    fmt.println("test future_await")
    run_one("var", test_var_await(), 4)
    run_one("factory", test_factory_await(), 4)
    run_one("mixed", test_mixed_await(), 4)
    run_one("leaf_static", test_leaf_static_await(), 9)
    fmt.println("future_await passed")
}
