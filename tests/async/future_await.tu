// Await erased runtime.Future and sync factories returning mem:async leaves.
// Assign factory then poll. Also covers nested typed/io.Buf fields on leaf futures.

use fmt
use io
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

// Typed mem field on async leaf survives poll without u64 bits.
mem NestInner {
	i32 tag
}
mem NestFieldFut: async {
	NestInner nest
}
NestFieldFut::poll(ctx) {
	if this.nest == null {
		return runtime.PollReady, 0.(i64)
	}
	if this.nest.tag != 42 {
		return runtime.PollReady, 1.(i64)
	}
	return runtime.PollReady, 0.(i64)
}
fn test_nest_typed_field() {
	fmt.println("test async nest typed field")
	h<NestFieldFut> = new NestFieldFut
	h.nest = new NestInner { tag: 42 }
	st<i32> = h.poll(0)
	if st != runtime.PollReady os.die("poll not ready")
	st2<i32> = h.poll(0)
	if st2 != runtime.PollReady os.die("poll2 not ready")
	if h.nest == null || h.nest.tag != 42 os.die("nest field lost across poll")
	fmt.println("test async nest typed field success")
}

// Value-nested io.Buf on async leaf survives Pending shrinks (full sizeof copy).
mem BufFieldFut: async {
	io.Buf remain
	i32 pad
}
BufFieldFut::poll(ctx) {
	if this.pad != 42 os.dief("pad corrupted: %d", this.pad)
	rem<io.Buf> = this.remain
	if io.buf_len(rem) == 0 {
		return runtime.PollReady, io.Ok
	}
	head<io.Buf>, tail<io.Buf> = rem.split_at(1)
	this.remain = tail
	return runtime.PollPending
}
fn test_nest_io_buf_field() {
	fmt.println("test async nest io.Buf field")
	b<io.Buf> = io.NewBuf(3)
	p<i8*> = b.ptr()
	p[0] = 1
	p[1] = 2
	p[2] = 3
	h<BufFieldFut> = new BufFieldFut
	h.pad = 42
	h.remain = b
	i<i32> = 0
	loop {
		st<i32>, code<i32> = h.poll(0)
		if st == runtime.PollReady {
			if code != io.Ok os.dief("ready bad code=%d", code)
			break
		}
		if st != runtime.PollPending os.dief("unexpected st=%d", st)
		i += 1
		if i > 8 os.die("too many pending")
	}
	if i != 3 os.dief("expected 3 pending got %d", i)
	if h.pad != 42 os.die("pad lost after drain")
	fmt.println("test async nest io.Buf field success")
}

fn main() {
    fmt.println("test future_await")
    run_one("var", test_var_await(), 4)
    run_one("factory", test_factory_await(), 4)
    run_one("mixed", test_mixed_await(), 4)
    run_one("leaf_static", test_leaf_static_await(), 9)
    test_nest_typed_field()
    test_nest_io_buf_field()
    fmt.println("future_await passed")
}
