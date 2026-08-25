// Embed PkgFS backend: read stdroot from compile-time EmbedFS.

use std
use string
use runtime

fn embed_path_has_prefix(name_ptr<i8*>, name_len<i32>, prefix_ptr<i8*>, prefix_len<i32>) i32 {
	if prefix_len == 0 {
		return 1
	}
	if name_len < prefix_len {
		return 0
	}
	pn<u64> = prefix_len.(u64)
	if std.memcmp(name_ptr, prefix_ptr, pn) != 0 {
		return 0
	}
	if name_len == prefix_len {
		return 1
	}
	sep_off<i32> = prefix_len
	sep_ptr<u64> = name_ptr + sep_off.(u64)
	sep<i8*> = sep_ptr
	if *sep != '/' {
		return 0
	}
	return 1
}

fn embed_list_filtered(_fs<runtime.EmbedFS>, dir_prefix, apply_overlay<i32>) i32 {
	out = []
	pre_p<i8*> = 0
	pre_n<i32> = 0
	if dir_prefix != null && dir_prefix != "" {
		pre_p = runtime.embed_dyn_name_ptr(dir_prefix)
		pre_n = runtime.embed_dyn_name_len(dir_prefix)
	}
	c<i32> = pkgfs_stdroot_count_slot
	t<u64> = pkgfs_stdroot_table_slot
	i<i32> = 0
	while i < c {
		np<u64>, nl<u64>, dp<u64>, dl<u64> = runtime.embed_entry_ptrs(t, i)
		npp<i8*> = np
		nln<i32> = nl.(i32)
		if pre_n > 0 {
			if embed_path_has_prefix(npp, nln, pre_p, pre_n) == 0 {
				i += 1
				continue
			}
		}
		name_s = string.newstringfromlen(npp, nln)
		fl = std.len(name_s)
		if pre_n > 0 && fl <= pre_n + 1 {
			i += 1
			continue
		}
		rest = name_s
		if pre_n > 0 {
			rest = string.sub(name_s, pre_n + 1)
		}
		if pkgfs_path_has_slash(rest) {
			i += 1
			continue
		}
		if apply_overlay != 0 {
			mapped = overlay_filter_basename(dir_prefix, rest, pkgfs_target)
			if mapped == "" {
				i += 1
				continue
			}
			rest = mapped
		}
		out[] = rest
		i += 1
	}
	pkgfs_list_cache = out
	return 0
}

fn embed_dir_has_tu(fs<runtime.EmbedFS>, dir_prefix) i32 {
	if embed_list_filtered(fs, dir_prefix, 0) != 0 {
		return 0
	}
	for name : pkgfs_list_cache {
		nlen = std.len(name)
		if nlen >= 3 && string.sub(name, nlen - 3) == ".tu" {
			return 1
		}
	}
	return 0
}

fn embed_resolve_repo_dir(fs<runtime.EmbedFS>, pkg_path) {
	cands = []
	cands[] = "library/" + pkg_path
	cands[] = "packages/" + pkg_path
	cands[] = pkg_path
	for dir : cands {
		if embed_dir_has_tu(fs, dir) != 0 {
			return dir
		}
	}
	return ""
}

fn embed_read_path(_fs<runtime.EmbedFS>, logical_path) (i32, i8*, i32) {
	z<i8*> = 0
	t<u64> = pkgfs_stdroot_table_slot
	c<i32> = pkgfs_stdroot_count_slot
	p<i8*> = runtime.embed_dyn_name_ptr(logical_path)
	n<i32> = runtime.embed_dyn_name_len(logical_path)
	if p == 0 {
		return 1, z, 0
	}
	err<i32>, data<i8*>, lenu<u64> = runtime.embed_find(t, c, p, n)
	if err != 0 {
		return 1, z, 0
	}
	sz<i32> = lenu.(i32)
	return 0, data, sz
}
