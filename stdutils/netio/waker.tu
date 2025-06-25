use netio.sys.unix
use netio

mem Waker {
    unix.Waker* inner
}

const Waker::new(registry<netio.Registry>, token<i32>) Waker {
    registry.register_waker()
    return new Waker{
        inner: unix.Waker::new(
            registry.selector(),
            token
        )
    }
}

Waker::wake() i32 {
    return this.inner.wake()
}