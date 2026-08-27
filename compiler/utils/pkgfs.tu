// PkgFS: unified stdlib lookup (embed memory tree vs disk copkg / TU_STD).

use std
use string
use runtime
use os
use fmt
use sys

PKGFS_MODE_EMBED<i32>   = 0
PKGFS_MODE_DISK<i32>    = 1
PKGFS_MODE_TU_STD<i32>  = 2

pkgfs_mode<i32> = PKGFS_MODE_EMBED
pkgfs_target<i32> = 0
pkgfs_stdroot<runtime.EmbedFS> = null
pkgfs_stdroot_table_slot<u64> = 0
pkgfs_stdroot_count_slot<i32> = 0
pkgfs_tu_std = ""
pkgfs_list_cache = []

fn pkgfs_take_list_cache() {
	return pkgfs_list_cache
}

fn pkgfs_list_finish(out) i32 {
	pkgfs_list_cache = out
	if std.len(out) <= 0 {
		return 1
	}
	return 0
}

fn pkgfs_set_stdroot_table(table<u64>, count<i32>) {
	pkgfs_stdroot_table_slot = table
	pkgfs_stdroot_count_slot = count
	if table == 0 || count <= 0 {
		pkgfs_stdroot = null
		return
	}
	pkgfs_stdroot = runtime.embed_fs_new(table, count)
}

// Expand embedded stdroot into a temp tree; subsequent lookup uses TU_STD disk paths.
fn pkgfs_materialize_stdroot() {
	t<u64> = pkgfs_stdroot_table_slot
	c<i32> = pkgfs_stdroot_count_slot
	if t == 0 || c <= 0 {
		return ""
	}
	root = path_join(host_tmpdir(), "tu-stdroot-" + strRand())
	host_mkdir_p(root)
	i<i32> = 0
	while i < c {
		np<u64>, nl<u64>, dp<u64>, dl<u64> = runtime.embed_entry_ptrs(t, i)
		npp<i8*> = np
		nln<i32> = nl.(i32)
		dpp<i8*> = dp
		name_s = string.newstringfromlen(npp, nln)
		out = path_join(root, name_s)
		dir = path_dirname(out)
		host_mkdir_p(dir)
		fp<i64> = std.fopen(*out, *"w")
		if fp >= 0 {
			std.fwrite(dpp, 1.(u64), dl, fp)
			std.fclose(fp)
		}
	i += 1
	}
	pkgfs_apply_target_overlay(root)
	return root
}

// Windows runtime auxiliaries installed from platform/windows/ (Makefile install-windows).
fn pkgfs_windows_runtime_aux() {
	return ["wsa_errno.tu", "fd_table.tu", "epoll_soft.tu", "sock_flags.tu", "pipe.tu"]
}

fn pkgfs_is_windows_runtime_aux(basename) i32 {
	for n : pkgfs_windows_runtime_aux() {
		if n == basename {
			return 1
		}
	}
	return 0
}

// Mirror Makefile install-{linux,darwin,windows} overlays onto a stdroot tree.
fn pkgfs_apply_target_overlay(root) {
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

fn pkgfs_rm(path) {
	if std.is_file(path) {
		sys.unlink(*path)
	}
}

fn pkgfs_copy_file(src, dst) {
	fs = new std.File(src)
	if !fs.IsOpen() {
		return
	}
	buf<i8*> = fs.ReadAllNative()
	tot = fs.size
	sz<i32> = 0
	if tot != null {
		sz = *tot
	}
	fs.Close()
	if buf == 0 || sz <= 0 {
		return
	}
	host_mkdir_p(path_dirname(dst))
	fp<i64> = std.fopen(*dst, *"w")
	if fp >= 0 {
		std.fwrite(buf, 1.(u64), sz.(u64), fp)
		std.fclose(fp)
	}
}

fn pkgfs_configure(mode<i32>, tu_std_path, _unused_bits<u64>, target<i32>) {
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
	if pkgfs_mode == PKGFS_MODE_EMBED && pkgfs_stdroot != null {
		if pkgfs_stdroot.count() <= 0 {
			notice("pkgfs: empty embed stdroot; falling back to disk copkg")
			pkgfs_mode = PKGFS_MODE_DISK
		}
	}
}

// Prefer string target name so overlay selection does not depend on class i32 0.
fn pkgfs_configure_named(mode<i32>, tu_std_path, target_name) {
	t<i32> = target_parse(target_name)
	if t < 0 {
		t = target_default()
	}
	pkgfs_configure(mode, tu_std_path, 0.(u64), t)
}

fn pkgfs_parse_mode_from_env() i32 {
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

fn pkgfs_tu_std_from_env() {
	v = env_get("TU_STD")
	if v != null && v != "" {
		return norm_slash(v)
	}
	return ""
}

fn pkgfs_path_has_slash(s) {
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

fn pkgfs_resolve_std_dir(pkg_path) {
	if pkgfs_mode == PKGFS_MODE_EMBED {
		if pkgfs_stdroot == null {
			return ""
		}
		return embed_resolve_repo_dir(pkgfs_stdroot, pkg_path)
	}
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

fn pkgfs_repo_std_dir(pkg_path) {
	if disk_dir_has_tu(path_join(pkgfs_tu_std, "library/" + pkg_path)) {
		return "library/" + pkg_path
	}
	if disk_dir_has_tu(path_join(pkgfs_tu_std, "packages/" + pkg_path)) {
		return "packages/" + pkg_path
	}
	return pkg_path
}

// Absolute package root for tu.mod lookup (must not walk from process cwd).
fn pkgfs_mode_root(pkg_path) {
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
	if pkgfs_mode == PKGFS_MODE_EMBED && pkgfs_stdroot != null {
		abs = embed_resolve_repo_dir(pkgfs_stdroot, pkg_path)
		if abs != "" {
			return abs
		}
	}
	return ""
}

fn pkgfs_list_runtime_tu() i32 {
	out = []
	want = overlay_runtime_name(pkgfs_target)
	if pkgfs_mode == PKGFS_MODE_EMBED {
		if embed_list_filtered(null, "runtime", 0) != 0 {
			pkgfs_list_cache = []
			return 1
		}
		raw = pkgfs_list_cache
		for name : raw {
			if name == "linux.tu" || name == "darwin.tu" || name == "windows.tu" {
				continue
			}
			if pkgfs_target != TARGET_WINDOWS && pkgfs_is_windows_runtime_aux(name) != 0 {
				continue
			}
			out[] = name
		}
		out[] = want
		if pkgfs_target == TARGET_WINDOWS {
			for n : pkgfs_windows_runtime_aux() {
				out[] = n
			}
		}
		return pkgfs_list_finish(out)
	}
	if pkgfs_mode == PKGFS_MODE_TU_STD {
		abs = path_join(pkgfs_tu_std, "runtime")
		raw = disk_list_tu(abs)
		// After materialize+overlay the tree already has the right *one* overlay file.
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
			// Drop Windows-only aux when not targeting Windows (raw TU_STD repo).
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
		// Raw TU_STD: inject Windows aux from platform/windows/ into the runtime list.
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
	abs = disk_resolve_copkg("runtime")
	if abs == "" {
		pkgfs_list_cache = []
		return 1
	}
	raw = disk_list_tu(abs)
	return pkgfs_list_finish(raw)
}

fn pkgfs_list_netio_sys_tu(std_dir) i32 {
	err<i32> = 0
	raw = []
	if pkgfs_mode == PKGFS_MODE_EMBED {
		if embed_list_filtered(pkgfs_stdroot, std_dir, 0) != 0 {
			pkgfs_list_cache = []
			return 1
		}
		raw = pkgfs_list_cache
		err = 0
	} else if pkgfs_mode == PKGFS_MODE_TU_STD {
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

fn pkgfs_list_package_tu(pkg_path) i32 {
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
	if pkgfs_mode == PKGFS_MODE_EMBED {
		err<i32> = embed_list_filtered(pkgfs_stdroot, std_dir, 1)
		if err != 0 {
			return 1
		}
		if std.len(pkgfs_list_cache) <= 0 {
			return 1
		}
		return 0
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

fn pkgfs_disk_source_path(std_dir, pkg_path, basename) {
	if pkg_path == "runtime" {
		if basename == "darwin.tu" {
			if pkgfs_mode == PKGFS_MODE_TU_STD {
				ov = path_join(pkgfs_tu_std, "runtime/darwin.tu")
				if std.is_file(ov) {
					return ov
				}
				return path_join(pkgfs_tu_std, "platform/darwin/runtime_os.tu")
			}
		}
		if basename == "windows.tu" {
			if pkgfs_mode == PKGFS_MODE_TU_STD {
				ov = path_join(pkgfs_tu_std, "runtime/windows.tu")
				if std.is_file(ov) {
					return ov
				}
				return path_join(pkgfs_tu_std, "platform/windows/runtime_os.tu")
			}
		}
		if basename == "linux.tu" {
			if pkgfs_mode == PKGFS_MODE_TU_STD {
				return path_join(pkgfs_tu_std, "runtime/linux.tu")
			}
		}
		if pkgfs_mode == PKGFS_MODE_TU_STD && pkgfs_target == TARGET_WINDOWS {
			if pkgfs_is_windows_runtime_aux(basename) != 0 {
				ov = path_join(pkgfs_tu_std, "runtime/" + basename)
				if std.is_file(ov) {
					return ov
				}
				return path_join(pkgfs_tu_std, "platform/windows/" + basename)
			}
		}
	}
	if std_dir == "library/os" && basename == "signal.tu" && pkgfs_mode == PKGFS_MODE_TU_STD {
		if pkgfs_target == TARGET_DARWIN {
			ov = path_join(pkgfs_tu_std, "library/os/signal.tu")
			// Prefer overlaid copy; raw TU_STD uses platform/darwin.
			plat = path_join(pkgfs_tu_std, "platform/darwin/os_signal.tu")
			if std.is_file(plat) {
				// After materialize, library/os/signal.tu is already Darwin; still OK to read plat.
				return plat
			}
			return ov
		}
	}
	if std_dir == "packages/netio/sys" && pkgfs_mode == PKGFS_MODE_TU_STD {
		if pkgfs_target == TARGET_DARWIN {
			if basename == "epoll.tu" {
				ov = path_join(pkgfs_tu_std, "packages/netio/sys/epoll.tu")
				if std.is_file(ov) {
					return ov
				}
				return path_join(pkgfs_tu_std, "packages/netio/sys/kqueue.tu")
			}
			if basename == "waker.tu" {
				ov = path_join(pkgfs_tu_std, "packages/netio/sys/waker.tu")
				if std.is_file(ov) {
					return ov
				}
				return path_join(pkgfs_tu_std, "packages/netio/sys/waker_kqueue.tu")
			}
			if basename == "platform.tu" {
				ov = path_join(pkgfs_tu_std, "packages/netio/sys/platform.tu")
				if std.is_file(ov) {
					return ov
				}
				return path_join(pkgfs_tu_std, "platform/darwin/netio_platform.tu")
			}
		}
		if pkgfs_target == TARGET_WINDOWS {
			if basename == "platform.tu" {
				ov = path_join(pkgfs_tu_std, "packages/netio/sys/platform.tu")
				if std.is_file(ov) {
					return ov
				}
				return path_join(pkgfs_tu_std, "platform/windows/netio_platform.tu")
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

// Materialize one embed source into workdir so Parser can open a real path.
fn pkgfs_materialize_embed(std_dir, pkg_path, basename) {
	rerr<i32>, buf<i8*>, sz<i32> = pkgfs_read_package_file(std_dir, pkg_path, basename)
	if rerr != 0 || buf == 0 || sz <= 0 {
		return ""
	}
	rel = ".pkgfs/" + std_dir + "/" + basename
	out = pathInWorkdir(rel)
	dir = path_dirname(out)
	host_mkdir_p(dir)
	fp<i64> = std.fopen(*out, *"w")
	if fp < 0 {
		return ""
	}
	wn<i64> = std.fwrite(buf, 1.(u64), sz.(u64), fp)
	std.fclose(fp)
	if wn != sz.(i64) && wn != sz.(u64) {
		// fwrite returns bytes written; tolerate platform width.
	}
	return out
}

fn pkgfs_logical_path(std_dir, basename) {
	return std_dir + "/" + basename
}

fn pkgfs_read_runtime(basename) (i32, i8*, i32) {
	want = overlay_runtime_name(pkgfs_target)
	if basename == want {
		if pkgfs_mode == PKGFS_MODE_EMBED {
			if pkgfs_target == TARGET_DARWIN {
				return embed_read_path(pkgfs_stdroot, "platform/darwin/runtime_os.tu")
			}
			if pkgfs_target == TARGET_WINDOWS {
				return embed_read_path(pkgfs_stdroot, "platform/windows/runtime_os.tu")
			}
			return embed_read_path(pkgfs_stdroot, "runtime/linux.tu")
		}
		if pkgfs_mode == PKGFS_MODE_TU_STD {
			// Prefer overlaid name; fall back to platform/ for raw TU_STD repo trees.
			ov = path_join(pkgfs_tu_std, "runtime/" + basename)
			if std.is_file(ov) {
				return disk_read_file(ov)
			}
			if pkgfs_target == TARGET_DARWIN {
				return disk_read_file(path_join(pkgfs_tu_std, "platform/darwin/runtime_os.tu"))
			}
			if pkgfs_target == TARGET_WINDOWS {
				return disk_read_file(path_join(pkgfs_tu_std, "platform/windows/runtime_os.tu"))
			}
			return disk_read_file(path_join(pkgfs_tu_std, "runtime/linux.tu"))
		}
		return disk_read_file(path_join(disk_resolve_copkg("runtime"), basename))
	}
	if pkgfs_is_windows_runtime_aux(basename) != 0 {
		if pkgfs_mode == PKGFS_MODE_EMBED {
			return embed_read_path(pkgfs_stdroot, "platform/windows/" + basename)
		}
		if pkgfs_mode == PKGFS_MODE_TU_STD {
			ov = path_join(pkgfs_tu_std, "runtime/" + basename)
			if std.is_file(ov) {
				return disk_read_file(ov)
			}
			return disk_read_file(path_join(pkgfs_tu_std, "platform/windows/" + basename))
		}
		return disk_read_file(path_join(disk_resolve_copkg("runtime"), basename))
	}
	if pkgfs_mode == PKGFS_MODE_EMBED {
		return embed_read_path(pkgfs_stdroot, "runtime/" + basename)
	}
	if pkgfs_mode == PKGFS_MODE_TU_STD {
		return disk_read_file(path_join(pkgfs_tu_std, "runtime/" + basename))
	}
	return disk_read_file(path_join(disk_resolve_copkg("runtime"), basename))
}

fn pkgfs_disk_pkg_dir(pkg_path) {
	return disk_resolve_copkg(pkg_path)
}

fn pkgfs_read_netio_sys(basename) (i32, i8*, i32) {
	std_dir = "packages/netio/sys"
	if pkgfs_mode == PKGFS_MODE_EMBED {
		if basename == "platform.tu" {
			if pkgfs_target == TARGET_DARWIN {
				return embed_read_path(pkgfs_stdroot, "platform/darwin/netio_platform.tu")
			}
			if pkgfs_target == TARGET_WINDOWS {
				return embed_read_path(pkgfs_stdroot, "platform/windows/netio_platform.tu")
			}
		}
		read_name = basename
		if pkgfs_target == TARGET_DARWIN {
			if basename == "epoll.tu" {
				read_name = "kqueue.tu"
			} else if basename == "waker.tu" {
				read_name = "waker_kqueue.tu"
			}
		}
		return embed_read_path(pkgfs_stdroot, pkgfs_logical_path(std_dir, read_name))
	}
	if pkgfs_mode == PKGFS_MODE_TU_STD {
		if basename == "platform.tu" {
			ov = path_join(pkgfs_tu_std, "packages/netio/sys/platform.tu")
			if std.is_file(ov) {
				return disk_read_file(ov)
			}
			if pkgfs_target == TARGET_DARWIN {
				return disk_read_file(path_join(pkgfs_tu_std, "platform/darwin/netio_platform.tu"))
			}
			if pkgfs_target == TARGET_WINDOWS {
				return disk_read_file(path_join(pkgfs_tu_std, "platform/windows/netio_platform.tu"))
			}
		}
		read_name = basename
		if pkgfs_target == TARGET_DARWIN {
			if basename == "epoll.tu" {
				ov = path_join(pkgfs_tu_std, "packages/netio/sys/epoll.tu")
				if std.is_file(ov) {
					return disk_read_file(ov)
				}
				read_name = "kqueue.tu"
			} else if basename == "waker.tu" {
				ov = path_join(pkgfs_tu_std, "packages/netio/sys/waker.tu")
				if std.is_file(ov) {
					return disk_read_file(ov)
				}
				read_name = "waker_kqueue.tu"
			}
		}
		return disk_read_file(path_join(path_join(pkgfs_tu_std, std_dir), read_name))
	}
	return disk_read_file(path_join(disk_resolve_copkg("netio/sys"), basename))
}

fn pkgfs_read_package_file(std_dir, pkg_path, basename) (i32, i8*, i32) {
	if pkg_path == "runtime" {
		return pkgfs_read_runtime(basename)
	}
	if std_dir == "packages/netio/sys" {
		return pkgfs_read_netio_sys(basename)
	}
	if std_dir == "library/os" && basename == "signal.tu" {
		if pkgfs_target == TARGET_DARWIN {
			if pkgfs_mode == PKGFS_MODE_EMBED {
				return embed_read_path(pkgfs_stdroot, "platform/darwin/os_signal.tu")
			}
			if pkgfs_mode == PKGFS_MODE_TU_STD {
				plat = path_join(pkgfs_tu_std, "platform/darwin/os_signal.tu")
				if std.is_file(plat) {
					return disk_read_file(plat)
				}
			}
		}
	}
	if pkgfs_mode == PKGFS_MODE_EMBED {
		return embed_read_path(pkgfs_stdroot, pkgfs_logical_path(std_dir, basename))
	}
	if pkgfs_mode == PKGFS_MODE_TU_STD {
		return disk_read_file(path_join(path_join(pkgfs_tu_std, std_dir), basename))
	}
	return disk_read_file(path_join(disk_resolve_copkg(pkg_path), basename))
}

fn pkgfs_scan_filepath(std_dir, basename) {
	return pkgfs_logical_path(std_dir, basename)
}

// Syscall .s tree for link: embed/TU_STD materialize first, else prefix coasm*.
fn pkgfs_coasm_dir() {
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

// Nostd entry stubs: embed platform/{darwin,windows}/stub_*.s, else prefix costub/copeff.
fn pkgfs_stub_dir() {
	if pkgfs_mode == PKGFS_MODE_TU_STD && pkgfs_tu_std != null && pkgfs_tu_std != "" {
		sub = ""
		if pkgfs_target == TARGET_DARWIN {
			sub = "platform/darwin"
		} else if pkgfs_target == TARGET_WINDOWS {
			sub = "platform/windows"
		}
		if sub != "" {
			d = path_join(pkgfs_tu_std, sub)
			probe = path_join(d, "stub_entry.s")
			if std.is_file(probe) {
				return d
			}
		}
	}
	lib = lib_root()
	if pkgfs_target == TARGET_DARWIN {
		return lib + "/costub-darwin"
	}
	if pkgfs_target == TARGET_WINDOWS {
		return lib + "/copeff"
	}
	return ""
}
