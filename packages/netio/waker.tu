use io
use netio.poll
use netio.sys.waker
use netio

mem Waker {
	waker.EventfdWaker* inner
}

const Waker::new(registry<poll.Registry>, t<netio.Token>) i32, Waker {
	err<i32> = registry.register_waker()
	if err != Ok
		return err, null
	err, inner<waker.EventfdWaker> = waker.EventfdWaker::new(registry.selector(), t)
	if err != Ok
		return err, null
	return Ok, new Waker { inner: inner }
}

Waker::wake() i32 {
	return this.inner.wake()
}
