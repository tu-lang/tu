use netio.event
use io
use netio.sys as nsys
use sys as libsys
use runtime

mem Poll {
	Registry* reg_store // mother: registry
}

// Mother: Registry { selector }.
mem Registry {
	nsys.Selector* sel
}

// Build Poll via single-return helpers (nested (i32,T) multi-return drops T).
fn poll_create() Poll {
	sel<nsys.Selector> = nsys.selector_create()
	if sel == null
		return null
	return new Poll {
		reg_store: new Registry { sel: sel }
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
    // All netio Sources wrap IoSource; register via IoSource bits (same end
    // as Registry → Source::enroll → selector). Keeps one path for driver bits.
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
		// Mother: Option::None → -1 (block forever). Duration::MAX must
		// NOT go through as_millis — secs*1000 overflows u64 and the
		// previous I32_MAX clamp left park hanging ~24 days instead of
		// waiting for an actual IO event.
		u64_max<u64> = 18446744073709551615
		if timeout.as_secs() == u64_max {
			timeout_ms = -1
		} else {
			ms<u64> = timeout.as_millis()
			imax<i32> = runtime.I32_MAX
			imax_u<u64> = imax.(u64)
			if ms > imax_u {
				timeout_ms = imax
			} else {
				timeout_ms = ms.(i32)
			}
		}
	}
	sel<nsys.Selector> = registry_selector(this.reg_store)
	return nsys.selector_select(sel, event.events_hub(events), timeout_ms)
}

Registry::try_clone() i32, Registry {
	sel<nsys.Selector> = registry_selector(this)
	err<i32>, bits<u64> = nsys.selector_try_clone_bits(sel)
	if err != io.Ok
		return err, null
	cloned<nsys.Selector> = nsys.selector_from_bits(bits)
	return io.Ok, new Registry { sel: cloned }
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
	return nsys.selector_to_bits(registry_selector(reg))
}

fn registry_selector(reg<Registry>) nsys.Selector {
	return reg.sel
}

fn poll_from_bits(bits<u64>) Poll {
    return bits.(Poll)
}

fn poll_sel_raw(p<Poll>) u64 {
    return registry_selector_bits(p.reg_store)
}

// Dummy arg: multi-return callee must have >=1 stack arg so caller keeps T.
fn make_poll(_unused<i32>) i32, Poll {
    p<Poll> = poll_create()
    if p == null
        return libsys.last_error(), null
    return io.Ok, p
}
