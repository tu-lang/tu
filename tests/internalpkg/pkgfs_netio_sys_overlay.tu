// pkgfs Darwin overlay: after embed materialize, epoll.tu must stay (kqueue body).
// Regression: list dropped lone epoll.tu → Events missing at parse.
// Assert via in-package bridge (cross-package Events loses hub pointer).
use fmt
use os
use netio.event as nevent

fn main() {
	ok = nevent.events_smoke_capacity(8.(u64))
	if ok != 1 {
		os.die("events_smoke_capacity failed (pkgfs overlay / Events hub)")
	}
	fmt.println("pkgfs netio overlay ok")
}
