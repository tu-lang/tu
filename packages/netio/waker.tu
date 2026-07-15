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
	err, inner<nsys.EventfdWaker> = nsys.EventfdWaker::new(sel, t.as_u64())
	if err != io.Ok
		return err, null
	return io.Ok, new Waker { inner: inner }
}

// Raw-bits Waker decode for callers outside this package.
fn waker_from_bits(bits<u64>) Waker {
    return bits.(Waker)
}

// Package-level constructor for cross-package callers.
fn make_waker(registry<Registry>, t<Token>) i32, Waker {
    err<i32> = 0
    out<Waker> = null
    err, out = Waker::new(registry, t)
    return err, out
}

// Package-level wake bridge (avoids w.wake parser trap).
fn waker_wake(w<Waker>) i32 {
    return w.wake()
}

Waker::wake() i32 {
	return this.inner.wake()
}
