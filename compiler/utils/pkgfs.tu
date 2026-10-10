// PkgFS: unified stdlib lookup (embed memory tree vs disk copkg / TU_STD).

use std
use string
use runtime
use os
use fmt
use sys

// Stdlib source modes. EMBED is only a request: pkgfs_configure materializes the
// embedded tree to a temp dir and switches to TU_STD (or DISK on failure).
PKGFS_MODE_EMBED   = 0
PKGFS_MODE_DISK    = 1
PKGFS_MODE_TU_STD  = 2

pkgfs_mode = 0
pkgfs_target = 0
pkgfs_stdroot = null   // runtime.EmbedFSObj from embed(...), or null
pkgfs_tu_std = ""
pkgfs_list_cache = []

func pkgfs_take_list_cache() {
	return pkgfs_list_cache
}

func pkgfs_list_finish(out) {
	pkgfs_list_cache = out
	if std.len(out) <= 0 {
		return 1
	}
	return 0
}

// Installs the embedded stdroot (an embed(...) object) used by materialize.
func pkgfs_set_stdroot(fs) {
	pkgfs_stdroot = fs
}


// Marker written last into a materialized stdroot; a tree without it is never trusted.
PKGFS_STDROOT_MARK = ".tu-stdroot-complete"
// Private (unpublished) stdroot of this process, removed by pkgfs_cleanup; "" if none.
pkgfs_private_root = ""

// Creates a private, fresh staging dir under TMPDIR, or returns "" after retries.
// The pid keeps concurrent tu processes apart (std.rand is seeded per second, so
// rand alone collides); ns clock + rand avoid stale dirs left by a dead pid.
func pkgfs_new_stdroot_dir() {
	tmp = host_tmpdir()
	host_mkdir_p(tmp)
	tries = 0
	while tries < 32 {
		root = path_join(tmp, fmt.sprintf(
			"tu-stdroot-tmp-%d-%d-%d",
			os.getpid(),
			std.ntime(),
			std.rand(1000000000)
		))
		tries += 1
		if std.is_dir(root) {
			continue
		}
		made = false
		unsafe {
			rc<i32> = sys.mkdir(*root, 511.(i64))
			if rc == 0 {
				made = true
			}
		}
		if made && std.is_dir(root) {
			return root
		}
	}
	return ""
}

// Content key of the embedded stdroot for the current target: FNV-1a over every
// entry's name and body hash. Appends [name, body] to files so each is read once.
func pkgfs_stdroot_key(names, files) {
	hi = 0
	lo = 0
	unsafe {
		h<u64> = 14695981039346656037
		for name : names {
			rerr, body = pkgfs_stdroot.read(name)
			if rerr != 0 {
				continue
			}
			files[] = [name, body]
			hn<u64> = runtime.get_hash_key(name)
			hb<u64> = runtime.get_hash_key(body)
			h = (h ^ hn) * 1099511628211
			h = (h ^ hb) * 1099511628211
		}
		h1<u64> = h >> 32
		h0<u64> = h & 4294967295
		hi = int(h1)
		lo = int(h0)
	}
	return fmt.sprintf("%d-%d-%d", pkgfs_target, hi, lo)
}

func pkgfs_stdroot_complete(root) {
	return std.is_file(path_join(root, PKGFS_STDROOT_MARK))
}

// Expands the embedded stdroot into a shared, content-addressed tree under TMPDIR
// (tu-stdroot-<target>-<hash>) and returns its path; "" on failure.
// A staging dir is filled and marked complete, then atomically renamed into place,
// so concurrent tu processes either publish or reuse a complete tree. When rename
// is unavailable (or the shared path is unusable) the staging tree is used privately
// and removed by pkgfs_cleanup.
func pkgfs_materialize_stdroot() {
	if pkgfs_stdroot == null {
		return ""
	}
	err, names = pkgfs_stdroot.list("")
	if err != 0 || std.len(names) <= 0 {
		return ""
	}
	files = []
	shared = path_join(host_tmpdir(), "tu-stdroot-" + pkgfs_stdroot_key(names, files))
	if pkgfs_stdroot_complete(shared) {
		return shared
	}
	root = pkgfs_new_stdroot_dir()
	if root == "" {
		return ""
	}
	for f : files {
		out = path_join(root, f[0])
		host_mkdir_p(path_dirname(out))
		host_write_file(out, f[1])
	}
	pkgfs_apply_target_overlay(root)
	host_write_file(path_join(root, PKGFS_STDROOT_MARK), "ok\n")
	if host_rename(root, shared) && pkgfs_stdroot_complete(shared) {
		return shared
	}
	// Lost the publish race: another process installed the same content first.
	if pkgfs_stdroot_complete(shared) {
		host_remove_tree(root)
		return shared
	}
	pkgfs_private_root = root
	return root
}

// Removes this process's private stdroot (if any). Shared trees are kept for reuse.
func pkgfs_cleanup() {
	if pkgfs_private_root == "" {
		return
	}
	host_remove_tree(pkgfs_private_root)
	pkgfs_private_root = ""
}


// Windows runtime auxiliaries installed from platform/windows/ (Makefile install-windows).
func pkgfs_windows_runtime_aux() {
	return ["wsa_errno.tu", "fd_table.tu", "epoll_soft.tu", "sock_flags.tu", "pipe.tu"]
}

func pkgfs_is_windows_runtime_aux(basename) {
	for n : pkgfs_windows_runtime_aux() {
		if n == basename {
			return 1
		}
	}
	return 0
}

// Mirror Makefile install-{linux,darwin,windows} overlays onto a stdroot tree.
func pkgfs_apply_target_overlay(root) {
	rt = path_join(root, "runtime")
	nsys = path_join(root, "packages/netio/sys")
	if pkgfs_target == TARGET_DARWIN {
		pkgfs_rm(path_join(rt, "linux.tu"))
		pkgfs_rm(path_join(rt, "windows.tu"))
		for n : pkgfs_windows_runtime_aux() {
			pkgfs_rm(path_join(rt, n))
		}
		pkgfs_copy_file(path_join(root, "platform/darwin/runtime_os.tu"), path_join(rt, "darwin.tu"))
		pkgfs_copy_file(path_join(root, "platform/darwin/os_signal.tu"), path_join(root, "library/os/signal.tu"))
		pkgfs_copy_file(path_join(root, "platform/darwin/netio_platform.tu"), path_join(nsys, "platform.tu"))
		pkgfs_copy_file(path_join(nsys, "kqueue.tu"), path_join(nsys, "epoll.tu"))
		pkgfs_rm(path_join(nsys, "kqueue.tu"))
		pkgfs_copy_file(path_join(nsys, "waker_kqueue.tu"), path_join(nsys, "waker.tu"))
		pkgfs_rm(path_join(nsys, "waker_kqueue.tu"))
		return
	}
	if pkgfs_target == TARGET_WINDOWS {
		pkgfs_rm(path_join(rt, "linux.tu"))
		pkgfs_rm(path_join(rt, "darwin.tu"))
		pkgfs_copy_file(path_join(root, "platform/windows/runtime_os.tu"), path_join(rt, "windows.tu"))
		for n : pkgfs_windows_runtime_aux() {
			pkgfs_copy_file(path_join(root, "platform/windows/" + n), path_join(rt, n))
		}
		pkgfs_copy_file(path_join(root, "platform/windows/netio_platform.tu"), path_join(nsys, "platform.tu"))
		pkgfs_rm(path_join(nsys, "kqueue.tu"))
		pkgfs_rm(path_join(nsys, "waker_kqueue.tu"))
		return
	}
	// Linux (default): keep runtime/linux.tu; drop foreign overlays + kqueue sources.
	pkgfs_rm(path_join(rt, "darwin.tu"))
	pkgfs_rm(path_join(rt, "windows.tu"))
	for n : pkgfs_windows_runtime_aux() {
		pkgfs_rm(path_join(rt, n))
	}
	pkgfs_rm(path_join(nsys, "kqueue.tu"))
	pkgfs_rm(path_join(nsys, "waker_kqueue.tu"))
}

func pkgfs_rm(path) {
	if std.is_file(path) {
		unsafe {
			sys.unlink(*path)
		}
	}
}

func pkgfs_copy_file(src, dst) {
	if !std.is_file(src) {
		return
	}
	host_mkdir_p(path_dirname(dst))
	copy_file(src, dst)
}


func pkgfs_configure(mode, tu_std_path, target) {
	pkgfs_mode = mode
	pkgfs_target = target
	pkgfs_tu_std = ""
	if tu_std_path != null && tu_std_path != "" {
		pkgfs_mode = PKGFS_MODE_TU_STD
		pkgfs_tu_std = norm_slash(tu_std_path)
	} else if mode == PKGFS_MODE_EMBED {
		root = pkgfs_materialize_stdroot()
		if root == null || root == "" {
			notice("pkgfs: embed materialize failed; falling back to disk copkg")
			pkgfs_mode = PKGFS_MODE_DISK
		} else {
			pkgfs_mode = PKGFS_MODE_TU_STD
			pkgfs_tu_std = root
			debugf("pkgfs: embed stdroot at %s", root)
		}
	}
}


// Prefer string target name so overlay selection does not depend on class i32 0.
func pkgfs_configure_named(mode, tu_std_path, target_name) {
	t = target_parse(target_name)
	if t < 0 {
		t = target_default()
	}
	pkgfs_configure(mode, tu_std_path, t)
}


func pkgfs_parse_mode_from_env() {
	v = env_get("TU_STD")
	if v != null && v != "" {
		return PKGFS_MODE_TU_STD
	}
	v = env_get("TU_STDLIB")
	if v == "disk" {
		return PKGFS_MODE_DISK
	}
	return PKGFS_MODE_EMBED
}

func pkgfs_tu_std_from_env() {
	v = env_get("TU_STD")
	if v != null && v != "" {
		return norm_slash(v)
	}
	return ""
}

func pkgfs_path_has_slash(s) {
	i = 0
	n = std.len(s)
	while i < n {
		if s[i] == '/' {
			return true
		}
		i += 1
	}
	return false
}

func pkgfs_resolve_std_dir(pkg_path) {
	if pkgfs_mode == PKGFS_MODE_TU_STD {
		if disk_resolve_repo_root(pkgfs_tu_std, pkg_path) != "" {
			return pkgfs_repo_std_dir(pkg_path)
		}
		return ""
	}
	dir = disk_resolve_copkg(pkg_path)
	if dir == "" {
		return ""
	}
	return pkg_path
}

func pkgfs_repo_std_dir(pkg_path) {
	if disk_dir_has_tu(path_join(pkgfs_tu_std, "library/" + pkg_path)) {
		return "library/" + pkg_path
	}
	if disk_dir_has_tu(path_join(pkgfs_tu_std, "packages/" + pkg_path)) {
		return "packages/" + pkg_path
	}
	return pkg_path
}

// Absolute package root for tu.mod lookup (must not walk from process cwd).
func pkgfs_mode_root(pkg_path) {
	if pkgfs_mode == PKGFS_MODE_DISK {
		abs = disk_resolve_copkg(pkg_path)
		if abs != "" {
			return abs
		}
	}
	if pkgfs_mode == PKGFS_MODE_TU_STD && pkgfs_tu_std != "" {
		abs = disk_resolve_repo_root(pkgfs_tu_std, pkg_path)
		if abs != "" {
			return abs
		}
	}
	return ""
}

func pkgfs_list_runtime_tu() {
	out = []
	want = overlay_runtime_name(pkgfs_target)
	// TU_STD repo tree and flat copkg: same target-aware filter + inject.
	// Disk keeps platform/ under copkg so cross --target works without re-overlay.
	rt_abs = ""
	if pkgfs_mode == PKGFS_MODE_TU_STD {
		rt_abs = path_join(pkgfs_tu_std, "runtime")
	} else {
		rt_abs = disk_resolve_copkg("runtime")
	}
	if rt_abs == "" {
		pkgfs_list_cache = []
		return 1
	}
	raw = disk_list_tu(rt_abs)
	has_ov = false
	seen = {}
	for name : raw {
		if name == "linux.tu" || name == "darwin.tu" || name == "windows.tu" {
			if name == want {
				has_ov = true
				out[] = name
				seen[name] = true
			}
			continue
		}
		if pkgfs_target != TARGET_WINDOWS && pkgfs_is_windows_runtime_aux(name) != 0 {
			continue
		}
		out[] = name
		seen[name] = true
	}
	if !has_ov {
		out[] = want
		seen[want] = true
	}
	if pkgfs_target == TARGET_WINDOWS {
		for n : pkgfs_windows_runtime_aux() {
			if !seen[n] {
				out[] = n
				seen[n] = true
			}
		}
	}
	return pkgfs_list_finish(out)
}

func pkgfs_list_netio_sys_tu(std_dir) {
	raw = []
	if pkgfs_mode == PKGFS_MODE_TU_STD {
		abs = path_join(pkgfs_tu_std, std_dir)
		raw = disk_list_tu(abs)
	} else {
		abs = path_join(copkg_dir(), "netio/sys")
		raw = disk_list_tu(abs)
	}
	// Raw repo / embed tree may have both epoll.tu and kqueue.tu. Prefer the
	// Darwin sources. Overlaid trees (materialize / install-darwin) only have
	// epoll.tu — must not drop it.
	has_kqueue = false
	has_waker_kq = false
	for name : raw {
		if name == "kqueue.tu" {
			has_kqueue = true
		}
		if name == "waker_kqueue.tu" {
			has_waker_kq = true
		}
	}
	seen = {}
	out = []
	for name : raw {
		if pkgfs_target == TARGET_DARWIN {
			if name == "epoll.tu" && has_kqueue {
				continue
			}
			if name == "waker.tu" && has_waker_kq {
				continue
			}
		}
		mapped = overlay_netio_sys_name(name, pkgfs_target)
		if mapped == "" {
			continue
		}
		if seen[mapped] {
			continue
		}
		seen[mapped] = true
		out[] = mapped
	}
	if pkgfs_target == TARGET_DARWIN || pkgfs_target == TARGET_WINDOWS {
		if !seen["platform.tu"] {
			out[] = "platform.tu"
		}
	}
	return pkgfs_list_finish(out)
}

func pkgfs_list_package_tu(pkg_path) {
	if pkg_path == "runtime" {
		return pkgfs_list_runtime_tu()
	}
	std_dir = pkgfs_resolve_std_dir(pkg_path)
	if std_dir == "" {
		pkgfs_list_cache = []
		return 1
	}
	if std_dir == "packages/netio/sys" {
		return pkgfs_list_netio_sys_tu(std_dir)
	}
	if pkgfs_mode == PKGFS_MODE_TU_STD {
		abs = path_join(pkgfs_tu_std, std_dir)
		raw = disk_list_tu(abs)
		out = []
		for name : raw {
			mapped = overlay_filter_basename(std_dir, name, pkgfs_target)
			if mapped == "" {
				continue
			}
			out[] = mapped
		}
		return pkgfs_list_finish(out)
	}
	abs = disk_resolve_copkg(pkg_path)
	if abs == "" {
		pkgfs_list_cache = []
		return 1
	}
	raw = disk_list_tu(abs)
	out = []
	for name : raw {
		mapped = overlay_filter_basename(std_dir, name, pkgfs_target)
		if mapped == "" {
			continue
		}
		out[] = mapped
	}
	return pkgfs_list_finish(out)
}

// Root of a disk-backed std tree: TU_STD path or flat copkg (includes platform/).
func pkgfs_disk_tree_root() {
	if pkgfs_mode == PKGFS_MODE_TU_STD && pkgfs_tu_std != "" {
		return pkgfs_tu_std
	}
	return copkg_dir()
}

func pkgfs_disk_source_path(std_dir, pkg_path, basename) {
	if pkg_path == "runtime" {
		tree = pkgfs_disk_tree_root()
		if basename == "darwin.tu" {
			if pkgfs_mode == PKGFS_MODE_TU_STD || pkgfs_mode == PKGFS_MODE_DISK {
				ov = path_join(tree, "runtime/darwin.tu")
				if std.is_file(ov) {
					return ov
				}
				return path_join(tree, "platform/darwin/runtime_os.tu")
			}
		}
		if basename == "windows.tu" {
			if pkgfs_mode == PKGFS_MODE_TU_STD || pkgfs_mode == PKGFS_MODE_DISK {
				ov = path_join(tree, "runtime/windows.tu")
				if std.is_file(ov) {
					return ov
				}
				return path_join(tree, "platform/windows/runtime_os.tu")
			}
		}
		if basename == "linux.tu" {
			if pkgfs_mode == PKGFS_MODE_TU_STD || pkgfs_mode == PKGFS_MODE_DISK {
				return path_join(tree, "runtime/linux.tu")
			}
		}
		if (pkgfs_mode == PKGFS_MODE_TU_STD || pkgfs_mode == PKGFS_MODE_DISK) && pkgfs_target == TARGET_WINDOWS {
			if pkgfs_is_windows_runtime_aux(basename) != 0 {
				ov = path_join(tree, "runtime/" + basename)
				if std.is_file(ov) {
					return ov
				}
				return path_join(tree, "platform/windows/" + basename)
			}
		}
	}
	if std_dir == "library/os" && basename == "signal.tu" && (pkgfs_mode == PKGFS_MODE_TU_STD || pkgfs_mode == PKGFS_MODE_DISK) {
		tree = pkgfs_disk_tree_root()
		if pkgfs_target == TARGET_DARWIN {
			ov = path_join(tree, "library/os/signal.tu")
			plat = path_join(tree, "platform/darwin/os_signal.tu")
			if std.is_file(plat) {
				return plat
			}
			return ov
		}
	}
	if std_dir == "packages/netio/sys" && (pkgfs_mode == PKGFS_MODE_TU_STD || pkgfs_mode == PKGFS_MODE_DISK) {
		tree = pkgfs_disk_tree_root()
		nsys = path_join(tree, "packages/netio/sys")
		if pkgfs_mode == PKGFS_MODE_DISK {
			nsys = path_join(tree, "netio/sys")
		}
		if pkgfs_target == TARGET_DARWIN {
			if basename == "epoll.tu" {
				ov = path_join(nsys, "epoll.tu")
				if std.is_file(ov) {
					return ov
				}
				return path_join(nsys, "kqueue.tu")
			}
			if basename == "waker.tu" {
				ov = path_join(nsys, "waker.tu")
				if std.is_file(ov) {
					return ov
				}
				return path_join(nsys, "waker_kqueue.tu")
			}
			if basename == "platform.tu" {
				ov = path_join(nsys, "platform.tu")
				if std.is_file(ov) {
					return ov
				}
				return path_join(tree, "platform/darwin/netio_platform.tu")
			}
		}
		if pkgfs_target == TARGET_WINDOWS {
			if basename == "platform.tu" {
				ov = path_join(nsys, "platform.tu")
				if std.is_file(ov) {
					return ov
				}
				return path_join(tree, "platform/windows/netio_platform.tu")
			}
		}
	}
	if pkgfs_mode == PKGFS_MODE_TU_STD {
		return path_join(path_join(pkgfs_tu_std, std_dir), basename)
	}
	abs = disk_resolve_copkg(pkg_path)
	if abs == "" {
		return ""
	}
	return path_join(abs, basename)
}


func pkgfs_logical_path(std_dir, basename) {
	return std_dir + "/" + basename
}





func pkgfs_scan_filepath(std_dir, basename) {
	return pkgfs_logical_path(std_dir, basename)
}

// Syscall .s tree for link: embed/TU_STD materialize first, else prefix coasm*.
func pkgfs_coasm_dir() {
	if pkgfs_target == TARGET_DARWIN {
		v = env_get("CO_DARWIN_COASM")
		if v != null && v != "" {
			return norm_slash(v)
		}
	}
	if pkgfs_target == TARGET_WINDOWS {
		v = env_get("CO_WINDOWS_COASM")
		if v != null && v != "" {
			return norm_slash(v)
		}
	}
	if pkgfs_mode == PKGFS_MODE_TU_STD && pkgfs_tu_std != null && pkgfs_tu_std != "" {
		sub = "syscall"
		if pkgfs_target == TARGET_DARWIN {
			sub = "syscall/darwin"
		} else if pkgfs_target == TARGET_WINDOWS {
			sub = "syscall/windows"
		}
		d = path_join(pkgfs_tu_std, sub)
		probe = path_join(d, "asm_amd64.s")
		if std.is_file(probe) {
			return d
		}
	}
	lib = lib_root()
	if pkgfs_target == TARGET_DARWIN {
		return lib + "/coasm-darwin"
	}
	if pkgfs_target == TARGET_WINDOWS {
		return lib + "/coasm-windows"
	}
	return lib + "/coasm"
}

// Nostd entry stubs: embed platform/<os>/stub_*.s, else prefix costub-darwin/copeff/costub-linux.
func pkgfs_stub_dir() {
	if pkgfs_mode == PKGFS_MODE_TU_STD && pkgfs_tu_std != null && pkgfs_tu_std != "" {
		sub = "platform/linux"
		if pkgfs_target == TARGET_DARWIN {
			sub = "platform/darwin"
		} else if pkgfs_target == TARGET_WINDOWS {
			sub = "platform/windows"
		}
		d = path_join(pkgfs_tu_std, sub)
		probe = path_join(d, "stub_entry.s")
		if std.is_file(probe) {
			return d
		}
	}
	lib = lib_root()
	if pkgfs_target == TARGET_DARWIN {
		return lib + "/costub-darwin"
	}
	if pkgfs_target == TARGET_WINDOWS {
		return lib + "/copeff"
	}
	return lib + "/costub-linux"
}
