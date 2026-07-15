use netio.event
use io
use netio.sys as nsys
use sys as libsys
use runtime

mem Poll {
	Registry* registry
}

mem Registry {
	nsys.Selector* sel // mother: selector; renamed (typeassert trap)
}

const Poll::new() i32, Poll {
	err<i32>, selector<nsys.Selector> = nsys.Selector::new()
	if err != io.Ok
		return err, null
	return io.Ok, new Poll {
		registry: new Registry { sel: selector }
	}
}

// Raw-bits Registry decode for callers outside this package.
fn registry_from_bits(bits<u64>) Registry {
    return bits.(Registry)
}

// Package-level registry bridge (avoids p.registry parser trap).
fn poll_registry(p<Poll>) Registry {
    return p.registry()
}

// Package-level poll bridge (avoids p.poll parser trap).
fn poll_poll(p<Poll>, events<event.Events>, timeout<libsys.Duration>) i32 {
    return p.poll(events, timeout)
}

fn registry_register(reg<Registry>, source_obj<event.Source>, t<Token>, interests<Interest>) i32 {
    return reg.register(source_obj, t, interests)
}

fn registry_deregister(reg<Registry>, source_obj<event.Source>) i32 {
    return reg.deregister(source_obj)
}

Poll::registry() Registry {
	return this.registry
}

Poll::poll(events<event.Events>, timeout<libsys.Duration>) i32 {
	timeout_ms<i32> = -1
	if timeout != null {
		ms<u64> = timeout.as_millis()
		imax<i32> = runtime.I32_MAX
		imax_u<u64> = imax.(u64)
		if ms > imax_u {
			timeout_ms = imax
		} else {
			timeout_ms = ms.(i32)
		}
	}
	return this.registry.sel.select(events.sys(), timeout_ms)
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
	err<i32>, selector<nsys.Selector> = this.sel.try_clone()
	if err != io.Ok
		return err, null
	return io.Ok, new Registry { sel: selector }
}

Registry::register_waker() i32 {
	if this.sel.register_waker()
		return io.AlreadyExists
	return io.Ok
}

// Expose mother Registry.selector() as a package helper.
fn registry_selector(reg<Registry>) nsys.Selector {
	return reg.sel
}

// Raw-bits Poll decode for callers outside this package.
fn poll_from_bits(bits<u64>) Poll {
    return bits.(Poll)
}

// Package-level constructor for cross-package callers.
fn make_poll() i32, Poll {
    err<i32> = 0
    out<Poll> = null
    err, out = Poll::new()
    return err, out
}
