// Host path helpers for the linker (kept local — must not depend on dyn compiler.utils).

use os
use std
use string
use runtime

unsafe fn char1(cn) {
	return runtime.newobject(runtime.Char, cn.(i8))
}

unsafe fn path_dirname_dyn(p) {
	n = std.len(p)
	i = n - 1
	while i >= 0 {
		if p[i] == '/' {
			if i == 0 {
				return "/"
			}
			out = ""
			j = 0
			while j < i {
				out += p[j]
				j += 1
			}
			return out
		}
		i -= 1
	}
	return p
}

unsafe fn lib_root() {
	for (k, v : os.envs()) {
		arr = string.split(v, "=")
		if std.len(arr) >= 2 {
			if arr[0] == "CO_PKG" && arr[1] != "" {
				return path_dirname_dyn(arr[1])
			}
		}
	}
	return "/usr/local/lib"
}

// Prefer TU_STD platform stubs, else prefix costub/copeff.
// kind: 1=darwin, 2=windows
unsafe fn stub_dir_for(kind) {
	for (k, v : os.envs()) {
		arr = string.split(v, "=")
		if std.len(arr) >= 2 {
			if arr[0] == "TU_STD" && arr[1] != "" {
				sub = ""
				if kind == 1 {
					sub = "platform/darwin"
				} else if kind == 2 {
					sub = "platform/windows"
				}
				if sub != "" {
					d = path_join(arr[1], sub)
					probe = path_join(d, "stub_entry.s")
					fp = fopen(probe, "r")
					if fp > 0 {
						fclose(fp)
						return d
					}
				}
			}
		}
	}
	lib = lib_root()
	if kind == 1 {
		return lib + "/costub-darwin"
	}
	if kind == 2 {
		return lib + "/copeff"
	}
	return ""
}

// Build argv for /bin/sh -c (mirrors os.system_argv; static-callable).
fn sh_argv(sh<u64>, cflag<u64>, cmd<u64>) {
	argv<i8*> = new 32
	p<u64*> = argv
	*p = sh
	p += 8
	*p = cflag
	p += 8
	*p = cmd
	p += 8
	*p = 0
	return argv
}

// Run /bin/sh -c cmd via std.fork/execve (static ABI — do not call export os.shell).
unsafe fn run_shell(cmd) {
	cstr<i8*> = *cmd
	argv<i8*> = sh_argv(*"sh", *"-c", cstr)
	pid<i64> = std.fork()
	if pid == 0 {
		std.execve(*"/bin/sh", argv, runtime.ori_envp)
		std.die(127.(i8))
	}
	st<i32> = 0
	sp<i32*> = &st
	std.waitpid(pid.(i32), sp.(u64), 0)
}

unsafe fn copy_file(src, dst) {
	run_shell("cp '" + src + "' '" + dst + "'")
}
