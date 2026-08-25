// pkgfs Darwin overlay: after embed materialize, epoll.tu must stay (kqueue body).
// Regression: list dropped lone epoll.tu → Events missing. Assert via make_events.
use fmt
use os
use netio.event as nevent
use netio.sys as netsys

fn main() {
	ev = nevent.make_events(8.(u64))
	hub = nevent.events_hub(ev)
	cap = netsys.events_get_capacity(hub)
	if cap != 8.(u64) {
		os.dief("Events capacity want 8 got %d", int(cap))
	}
	n = netsys.events_slot_count(hub)
	if n != 0.(u64) {
		os.dief("Events count want 0 got %d", int(n))
	}
	fmt.println("pkgfs netio overlay ok")
}
