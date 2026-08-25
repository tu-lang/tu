// Target overlay selection for embed/TU_STD stdroot (RFC-107 §7.3).

// Runtime overlay basename for a compile --target (not host OS).
fn overlay_runtime_name(target<i32>) {
	if target == TARGET_DARWIN {
		return "darwin.tu"
	}
	if target == TARGET_WINDOWS {
		return "windows.tu"
	}
	return "linux.tu"
}

// Map netio/sys filenames for darwin/windows; empty skip, non-empty may rename.
// Darwin install / embed materialize already rewrite epoll.tu←kqueue and drop
// kqueue.tu. Listing must still keep epoll.tu / waker.tu / platform.tu on that
// tree. Prefer kqueue* when both raw names exist (see pkgfs_list_netio_sys_tu).
fn overlay_netio_sys_name(basename, target<i32>) {
	if target == TARGET_DARWIN {
		if basename == "kqueue.tu" {
			return "epoll.tu"
		}
		if basename == "waker_kqueue.tu" {
			return "waker.tu"
		}
		return basename
	}
	if target == TARGET_WINDOWS {
		if basename == "kqueue.tu" || basename == "waker_kqueue.tu" {
			return ""
		}
		if basename == "linux.tu" || basename == "darwin.tu" {
			return ""
		}
		return basename
	}
	// Linux: drop darwin-only sources; keep epoll/waker as-is.
	if basename == "kqueue.tu" || basename == "waker_kqueue.tu" {
		return ""
	}
	if basename == "darwin.tu" || basename == "windows.tu" {
		return ""
	}
	return basename
}

// Apply overlay rules for generic package directories (not runtime/netio special cases).
fn overlay_filter_basename(pkg_dir, basename, target<i32>) {
	if pkg_dir == "packages/netio/sys" {
		return overlay_netio_sys_name(basename, target)
	}
	if basename == "linux.tu" || basename == "darwin.tu" || basename == "windows.tu" {
		return ""
	}
	return basename
}
