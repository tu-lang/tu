// Disk PkgFS backend: flat copkg install or TU_STD repo tree.

use std
use string

func disk_dir_has_tu(dir) {
	if !std.is_dir(dir) {
		return false
	}
	names = list_dir_basenames(dir)
	for name : names {
		nlen = std.len(name)
		if nlen >= 3 && string.sub(name, nlen - 3) == ".tu" {
			return true
		}
	}
	return false
}

// Repo layout: library/pkg, packages/pkg, or top-level runtime/...
func disk_resolve_repo_root(root, pkg_path) {
	cands = []
	cands[] = path_join(root, "library/" + pkg_path)
	cands[] = path_join(root, "packages/" + pkg_path)
	cands[] = path_join(root, pkg_path)
	for dir : cands {
		if disk_dir_has_tu(dir) {
			return dir
		}
	}
	return ""
}

func disk_resolve_copkg(pkg_path) {
	v = env_get("CO_PKG")
	if v != null && v != "" {
		dir = path_join(norm_slash(v), pkg_path)
		if std.is_dir(dir) && disk_dir_has_tu(dir) {
			return dir
		}
	}
	dir = path_join(copkg_dir(), pkg_path)
	if std.is_dir(dir) && disk_dir_has_tu(dir) {
		return dir
	}
	fallback = path_join("/usr/local/lib/copkg", pkg_path)
	if std.is_dir(fallback) && disk_dir_has_tu(fallback) {
		return fallback
	}
	return ""
}

func disk_list_tu(dir) {
	out = []
	names = list_dir_basenames(dir)
	for name : names {
		if name == "." || name == ".." {
			continue
		}
		nlen = std.len(name)
		if nlen < 3 {
			continue
		}
		if string.sub(name, nlen - 3) != ".tu" {
			continue
		}
		out[] = name
	}
	return out
}

