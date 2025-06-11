use netio.sys.unix.selector

mem Poll {
    Registry* registry
}

mem Registry {
    selector.Selector* selector
}


const Poll::new() Poll {
    return new Poll {
        registry:  new Registry {
            selector: selector.Selector::new()
        }
    }
}

Poll::registry() Registry {
    return this.registry
}


Poll::poll(events<event.Events>, timeout<i64>) i32 {
    return this.registry.selector.select(events.sys(), timeout)
}

Poll::as_raw_fd() -> RawFd {
    this.registry.as_raw_fd()
}

//TODO: source type unknown
Registry::register(source<IoSource>, token<i32>, interests<Interest>) i32 {
    runtime.tracef(
        *"registering event source with poller: token=%d, interests=%d",
        token,
        interests
    )
    return source.register(this, token, interests)
}
//TODO: source type unknown
Registry::reregister(source<IoSource>, token<i32>, interests< Interest>) i32 {
    trace(
        *"reregistering event source with poller: token=%d, interests=%d",
        token,
        interests
    )
    return source.reregister(this, token, interests)
}

Registry::deregister(source<IoSource>) i32 {
{
    runtime.trace(*"deregistering event source from poller")
    return source.deregister(this)
}

Registry::try_clone() Registry {
    return new Registry {
        selector: this.selector.try_clone()
    }
}

Registry::register_waker()  Registry{
    ret<i32> = this.selector.register_waker()
    if ret != true {
        runtime.error(
            *"Only a single `Waker` can be active per `Poll` instance\n"
        )

    }
}

Registry::selector() selector.Selector {
    return this.selector
}

Registry::as_raw_fd() i32 {
    return this.selector.as_raw_fd()
}

