use netio.event
use io
use netio.sys as nsys
use sys as libsys
use runtime

mem Poll {
	Registry* reg_store // mother: registry
}

// Mother: Registry { selector }. Store Selector as u64 — cross-package
// `Selector*` field loads / member calls segfault under current codegen.
mem Registry {
	u64 sel_raw // mother: selector
}

// Build Poll via single-return helpers (nested (i32,T) multi-return drops T).
fn poll_create() Poll {
	sel<nsys.Selector> = nsys.selector_create()
	if sel == null
		return null
	return new Poll {
		reg_store: new Registry { sel_raw: nsys.selector_to_bits(sel) }
	}
}

const Poll::new(_unused<i32>) i32, Poll {
	p<Poll> = poll_create()
	if p == null
		return libsys.last_error(), null
	return io.Ok, p
}

fn registry_from_bits(bits<u64>) Registry {
    return bits.(Registry)
}

fn poll_registry(p<Poll>) Registry {
    return p.reg_store
}

fn poll_poll(p<Poll>, events<event.Events>, timeout<libsys.Duration>) i32 {
    return p.poll(events, timeout)
}

fn registry_register(reg<Registry>, iosrc_bits<u64>, t<Token>, interests<Interest>) i32 {
    // Bypass event.Source api dispatch (`.enroll` / `.register` segfault under
    // current codegen). All netio Sources wrap IoSource; mother still goes
    // Registry::register → Source::register → selector.
    return iosource_register_bits(iosrc_bits, reg, t, interests)
}

fn registry_deregister(reg<Registry>, iosrc_bits<u64>) i32 {
    return iosource_deregister_bits(iosrc_bits, reg)
}

fn registry_reregister(reg<Registry>, iosrc_bits<u64>, t<Token>, interests<Interest>) i32 {
    return iosource_reregister_bits(iosrc_bits, reg, t, interests)
}

Poll::registry() Registry {
	return this.reg_store
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
	sel<nsys.Selector> = registry_selector(this.reg_store)
	return nsys.selector_select(sel, events.sys(), timeout_ms)
}

Registry::try_clone() i32, Registry {
	sel<nsys.Selector> = registry_selector(this)
	err<i32>, bits<u64> = nsys.selector_try_clone_bits(sel)
	if err != io.Ok
		return err, null
	return io.Ok, new Registry { sel_raw: bits }
}

// Mother: assert!(!selector.register_waker()).
Registry::register_waker() i32 {
	sel<nsys.Selector> = registry_selector(this)
	prev<i32> = nsys.selector_register_waker_bit(sel)
	if prev != 0
		return io.AlreadyExists
	return io.Ok
}

fn registry_selector_bits(reg<Registry>) u64 {
	return reg.sel_raw
}

fn registry_selector(reg<Registry>) nsys.Selector {
	bits<u64> = registry_selector_bits(reg)
	return nsys.selector_from_bits(bits)
}

fn poll_from_bits(bits<u64>) Poll {
    return bits.(Poll)
}

fn poll_sel_raw(p<Poll>) u64 {
    r<Registry> = p.reg_store
    return r.sel_raw
}

// Dummy arg: multi-return callee must have >=1 stack arg so caller keeps T.
fn make_poll(_unused<i32>) i32, Poll {
    p<Poll> = poll_create()
    if p == null
        return libsys.last_error(), null
    return io.Ok, p
}
