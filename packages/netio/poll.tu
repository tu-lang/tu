use netio.event.events
use netio.event.source
use netio.interest
use io
use netio.sys.epoll
use sys
use netio

mem Poll {
	Registry* registry
}

mem Registry {
	epoll.Selector* selector
}

const Poll::new() i32, Poll {
	err<i32>, selector<epoll.Selector> = epoll.Selector::new()
	if err != Ok
		return err, null
	return Ok, new Poll {
		registry: new Registry { selector: selector }
	}
}

Poll::registry() Registry {
	return this.registry
}

Poll::poll(events<events.Events>, timeout<sys.Duration>) i32 {
	return this.registry.selector.select(events.sys(), timeout)
}

Registry::register(source_obj<source.Source>, t<netio.Token>, interests<interest.Interest>) i32 {
	return source_obj.register(this, t, interests)
}

Registry::reregister(source_obj<source.Source>, t<netio.Token>, interests<interest.Interest>) i32 {
	return source_obj.reregister(this, t, interests)
}

Registry::deregister(source_obj<source.Source>) i32 {
	return source_obj.deregister(this)
}

Registry::try_clone() i32, Registry {
	err<i32>, selector<epoll.Selector> = this.selector.try_clone()
	if err != Ok
		return err, null
	return Ok, new Registry { selector: selector }
}

Registry::register_waker() i32 {
	if this.selector.register_waker()
		return io.AlreadyExists
	return Ok
}

Registry::selector() epoll.Selector {
	return this.selector
}
