// Host-side process/file helpers for the driver (tulang.tu).
// Unix hosts shell out via /bin/sh; Windows hosts use the os.win_* thunks
// (no cmd.exe interpolation: commands run through CreateProcessA directly).

use os
use std
use sys
use runtime
use fmt
use string

func is_windows_host() {
	if runtime.host_os() == 2 {
		return true
	}
	return false
}

// Replace backslashes with forward slashes (Win32 APIs accept both; the
// toolchain normalizes early so .string paths never carry backslashes).
func norm_slash(path) {
	out = ""
	i = 0
	n = std.len(path)
	bs = char1(92.(i8))
	while i < n {
		c = path[i]
		if c == bs {
			out += "/"
		} else {
			out += c
		}
		i += 1
	}
	return out
}

// Run a host command; returns the child exit code (unix os.shell path
// reports 0 because sh status is not surfaced; callers check artifacts).
func host_run(cmd) {
	if is_windows_host() {
		return win_run(cmd)
	}
	os.shell(cmd)
	return 0
}

// CreateProcessA + WaitForSingleObject + GetExitCodeProcess.
func win_run(cmd) {
	si<i8*> = new 112
	sib<u64> = si
	std.memset(sib, 0, 112)
	p32<u32*> = si
	*p32 = 104
	pi<i8*> = new 32
	pib<u64> = pi
	std.memset(pib, 0, 32)
	ok<i32> = os.win_create_process(*cmd, si, pi)
	if ok == 0 {
		fmt.printf("[tu] CreateProcess failed: %s\n", cmd)
		return -1
	}
	hp<u64*> = pi
	h<u64> = *hp
	htp<u64*> = pi + 8
	ht<u64> = *htp
	os.win_wait_object(h)
	code<i32> = -1
	os.win_exit_code(h, &code)
	os.win_close_handle(h)
	os.win_close_handle(ht)
	return int(code)
}

// Binary file copy via std fds. Returns 0 on success.
func copy_file(src, dst) {
	sfd<i32> = std.fopen(*src, *"r")
	if sfd <= 0 {
		return -1
	}
	dfd<i32> = std.fopen(*dst, *"w+")
	if dfd <= 0 {
		std.fclose(sfd)
		return -1
	}
	buf<u64*> = new 65536
	sz<i64> = 65536
	loop {
		n<i64> = std.read(sfd, buf, sz)
		if n <= 0 {
			break
		}
		one<i8> = 1
		std.fwrite(buf, n, one, dfd)
	}
	std.fclose(sfd)
	std.fclose(dfd)
	return 0
}

// mkdir one level (0777); ok if it already exists.
func host_mkdir(dir) {
	sys.mkdir(*dir, 511.(i64))
	return std.is_dir(dir)
}

// mkdir -p equivalent: create each missing path component.
func host_mkdir_p(dir) {
	if std.is_dir(dir) {
		return true
	}
	d = norm_slash(dir)
	n = std.len(d)
	i = 0
	cur = ""
	while i < n {
		c = d[i]
		cur += c
		if c == '/' && i > 0 {
			// Skip drive roots like "C:/" and the leading "/".
			if !std.is_dir(cur) {
				sys.mkdir(*cur, 511.(i64))
			}
		}
		i += 1
	}
	if !std.is_dir(cur) {
		sys.mkdir(*cur, 511.(i64))
	}
	return std.is_dir(dir)
}

// Delete every regular file in dir whose name ends with ext.
func remove_files_ext(dir, ext) {
	if !std.is_dir(dir) {
		return false
	}
	extlen = std.len(ext)
	names = list_dir_basenames(dir)
	for name : names {
		if name == "." || name == ".." {
			continue
		}
		flen = std.len(name)
		if flen < extlen {
			continue
		}
		if string.sub(name, flen - extlen) == ext {
			fp = path_join(dir, name)
			sys.unlink(*fp)
		}
	}
	return true
}

// Copy every file in src_dir ending with ext into dst_dir (flat).
func copy_dir_ext(src_dir, dst_dir, ext) {
	if !std.is_dir(src_dir) {
		return false
	}
	extlen = std.len(ext)
	names = list_dir_basenames(src_dir)
	for name : names {
		if name == "." || name == ".." {
			continue
		}
		flen = std.len(name)
		if flen < extlen {
			continue
		}
		if string.sub(name, flen - extlen) != ext {
			continue
		}
		src = path_join(src_dir, name)
		dst = path_join(dst_dir, name)
		copy_file(src, dst)
	}
	return true
}

// TMPDIR (unix) / TEMP / TMP (windows) / "/tmp" fallback.
func host_tmpdir() {
	if std.exist("TMPDIR", envs) && envs["TMPDIR"] != "" {
		return norm_slash(envs["TMPDIR"])
	}
	if std.exist("TEMP", envs) && envs["TEMP"] != "" {
		return norm_slash(envs["TEMP"])
	}
	if std.exist("TMP", envs) && envs["TMP"] != "" {
		return norm_slash(envs["TMP"])
	}
	return "/tmp"
}

// List basenames in dir via FindFirstFile (Windows) or opendir (unix).
// Returns a dynamic array of basename strings (files and dirs, including . / ..).
func list_dir_basenames(dir) {
	out = []
	if is_windows_host() {
		pat = ""
		i = 0
		dn = std.len(dir)
		bs = char1(92.(i8))
		while i < dn {
			c = dir[i]
			if c == '/' {
				pat += "\\"
			} else {
				pat += c
			}
			i += 1
		}
		if dn > 0 {
			last = pat[std.len(pat) - 1]
			if last != bs {
				pat = pat + "\\"
			}
		}
		pat = pat + "*"
		h<u64> = os.win_find_first(*pat)
		if h == 0 {
			return out
		}
		loop {
			np<i8*> = os.win_find_name()
			# Copy out of the shared win_find_name buffer before FindNext.
			nm = "" + string.new(np)
			out[] = nm
			rc<i32> = os.win_find_next(h)
			if rc == 0 {
				break
			}
		}
		os.win_find_close(h)
		return out
	}
	fd = std.opendir(dir)
	if !fd {
		return out
	}
	loop {
		f = fd.readdir()
		if !f {
			break
		}
		out[] = f.name
	}
	return out
}
