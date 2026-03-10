use io
use netio.sys

mem Waker {
	sys.EventfdWaker* inner
}

const Waker::new(registry<Registry>, t<Token>) i32, Waker {
	err<i32> = registry.register_waker()
	if err != Ok
		return err, null
	err, inner<sys.EventfdWaker> = sys.EventfdWaker::new(registry.selector(), t)
	if err != Ok
		return err, null
	return Ok, new Waker { inner: inner }
}

Waker::wake() i32 {
	return this.inner.wake()
}
