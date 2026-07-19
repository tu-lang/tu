use io
use netio.sys as nsys

mem Waker {
	nsys.EventfdWaker* inner
}

const Waker::new(registry<Registry>, t<Token>) i32, Waker {
	err<i32> = registry.register_waker()
	if err != io.Ok
		return err, null
	sel<nsys.Selector> = registry_selector(registry)
	tok<u64> = t.as_u64()
	err, inner<nsys.EventfdWaker> = nsys.EventfdWaker::new(sel, tok)
	if err != io.Ok
		return err, null
	return io.Ok, new Waker { inner: inner }
}

fn waker_from_bits(bits<u64>) Waker {
    return bits.(Waker)
}

fn make_waker(registry<Registry>, t<Token>) i32, Waker {
    err<i32>, out<Waker> = Waker::new(registry, t)
    return err, out
}

fn waker_wake(w<Waker>) i32 {
    return w.wake()
}

Waker::wake() i32 {
	return this.inner.wake()
}
