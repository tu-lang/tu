use netio.event
use io
use netio.sys
use sys

mem Poll {
	Registry* registry
}

mem Registry {
	sys.Selector* selector
}

const Poll::new() i32, Poll {
	err<i32>, selector<sys.Selector> = sys.Selector::new()
	if err != Ok
		return err, null
	return Ok, new Poll {
		registry: new Registry { selector: selector }
	}
}

Poll::registry() Registry {
	return this.registry
}

Poll::poll(events<event.Events>, timeout<sys.Duration>) i32 {
	return this.registry.selector.select(events.sys(), timeout)
}

Registry::register(source_obj<event.Source>, t<Token>, interests<Interest>) i32 {
	return source_obj.register(this, t, interests)
}

Registry::reregister(source_obj<event.Source>, t<Token>, interests<Interest>) i32 {
	return source_obj.reregister(this, t, interests)
}

Registry::deregister(source_obj<event.Source>) i32 {
	return source_obj.deregister(this)
}

Registry::try_clone() i32, Registry {
	err<i32>, selector<sys.Selector> = this.selector.try_clone()
	if err != Ok
		return err, null
	return Ok, new Registry { selector: selector }
}

Registry::register_waker() i32 {
	if this.selector.register_waker()
		return io.AlreadyExists
	return Ok
}

Registry::selector() sys.Selector {
	return this.selector
}
