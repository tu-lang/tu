use std
use std.map
use runtime
use string
use fmt
use os


// Dyn bool facade for class methods (`if utils.has(key, map)`).
// Arg order matches std.exist: (key, map_or_array).
// Do not call map_has() from here: fn i32 0 is returned as null Value* across
// dyn ABI and breaks `hit = map_has(...)`.
func has(key, m){
	if m == null {
		return false
	}
	unsafe {
		mv<runtime.Value> = m
		if mv.type == runtime.Map {
			hit<u64> = map.map_find(mv, key)
			if hit != 0.(u64) {
				return true
			}
			return false
		}
		if mv.type == runtime.Array {
			if runtime.array_in(key, mv.data) == runtime.True {
				return true
			}
			return false
		}
	}
	return false
}

func hash(data){
	unsafe {
		return int(runtime.get_hash_key(data))
	}
}
// func ALIGN_DOWN(x<u64>,a<u64>) {
func ALIGN_DOWN(x,a) {
	return ALIGN_UP(x - a + 1,a)
}
// func ALIGN_UP(x<u64> , a<u64>) {
func ALIGN_UP(x , a) {
	return ( x + (a - 1) ) & ( ~ (a - 1))
}
func max(l,r){
	if l > r return l
	return r
}
func pwd(){
	if is_windows_host() {
		cwd = ""
		unsafe {
			buf<i8*> = new 260
			n<i32> = os.win_getcwd(buf, 260.(i32))
			if n > 0 {
				cwd = string.new(buf)
			}
		}
		if cwd != "" {
			return norm_slash(cwd)
		}
	}
	v = env_get("PWD")
	if v != "" {
		return norm_slash(v)
	}
	return ""
}
func strRand() {			
	v = std.rand(1000000000)
	return fmt.sprintf("%D",v)
}
func isUpper(str)
{
	return str[0] >= 'A' && str[0] <= 'Z'
}

// Prefix test for dynamic strings (string.sub is start-index only, no length).
func str_starts_with(s, prefix) {
	plen = std.len(prefix)
	slen = std.len(s)
	if slen < plen return false
	i = 0
	while i < plen {
		if s[i] != prefix[i] return false
		i += 1
	}
	return true
}

func path_is_sep(c) {
	if c == '/' {
		return true
	}
	if c == '\\' {
		return true
	}
	return false
}

// Parent directory; no slash → "." (accepts / and \).
func path_dirname(path){
	n = std.len(path)
	if n == 0 return "."
	i = n - 1
	while i >= 0 {
		if path_is_sep(path[i]) break
		i -= 1
	}
	if i < 0 return "."
	if i == 0 return "/"
	out = ""
	j = 0
	while j < i {
		out += path[j]
		j += 1
	}
	return out
}
func path_basename(path){
	n = std.len(path)
	if n == 0 return path
	i = n - 1
	while i >= 0 {
		if path_is_sep(path[i]) break
		i -= 1
	}
	if i < 0 return path
	return string.sub(path, i + 1)
}
func path_join(d,f){
	if d == null || d == "" || d == "."
		return f
	dlen = std.len(d)
	last = d[dlen - 1]
	if path_is_sep(last)
		return d + f
	return d + "/" + f
}

func make_tu_build_dir(stem){
	tmp = host_tmpdir()
	safe = ""
	i = 0
	slen = std.len(stem)
	while i < slen {
		c = stem[i]
		if (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_' || c == '-' {
			safe += c
		}else{
			safe += "_"
		}
		i += 1
	}
	if safe == "" safe = "main"
	if std.len(safe) > 48 {
		t = ""
		j = 0
		while j < 48 {
			t += safe[j]
			j += 1
		}
		safe = t
	}
	tries = 0
	while tries < 32 {
		dir = tmp + "/tu-build-" + safe + "-" + fmt.sprintf(
			"%d-%d-%d",
			os.getpid(),
			std.ntime(),
			std.rand(1000000000)
		)
		if std.is_dir(dir) {
			tries += 1
			continue
		}
		host_mkdir(dir)
		if std.is_dir(dir) return dir
		tries += 1
	}
	os.die("make_tu_build_dir: failed after retries")
	return ""
}

workdir = ""
// True only when workdir is a private TMPDIR/tu-build-* dir created by this
// process (not --workdir / --workdir-cwd), so it may be removed after use.
workdir_auto = false

func pathInWorkdir(basename){
	if workdir == null || workdir == ""
		return basename
	return path_join(workdir, basename)
}

func initWorkdir(code_file, use_cwd, explicit_dir){
	if use_cwd {
		workdir = ""
		fmt.printf("[tu] workdir: (cwd)\n")
		return
	}
	if explicit_dir != null && explicit_dir != "" {
		if !std.is_dir(explicit_dir) {
			host_mkdir_p(explicit_dir)
		}
		workdir = explicit_dir
		fmt.printf("[tu] workdir: %s\n", workdir)
		return
	}
	stem = path_basename(code_file)
	parts = string.split(stem,".")
	if std.len(parts) > 1 {
		stem = parts[0]
	}
	workdir = make_tu_build_dir(stem)
	workdir_auto = true
	fmt.printf("[tu] workdir: %s\n", workdir)
}

// Removes the private auto workdir (no-op for --workdir / --workdir-cwd).
func cleanupWorkdir(){
	if !workdir_auto return
	host_remove_tree(workdir)
	workdir_auto = false
}

specs = {
	"\\n"  : 10,
	"\\\\" : 92,
	"\\t"  : 9,
	"\\\'" : 39,
	"\\\"" : 34,
	"\\b"  : 8,
	"\\r"  : 13,
	"\\f"  : 12,
	"\\0"  : 0,
	"\\r"  : 13,
	"\\v"  : 11
}
// Expands backslash escapes of a string literal body into raw bytes.
unsafe func getescapestr(dstr){
	dv<runtime.Value> = dstr
	str<string.Str> = dv.data
	i<i32>  = 0
	total<i32> = str.len()
	p<i8*> = str
	// Map misses return the shared internal_null Value, not a zero pointer.
	rnull<u64> = &runtime.internal_null
	lex<string.String> = string.emptyS()
	while i < total {
		c<i8> = p[i]
		if c == '\\' {
			i += 1
			c = p[i]
			ts = "\\" + string.tostring(runtime.newobject(runtime.Char, c))
			sv<runtime.Value> = specs[ts]
			if ts == "\\0" {
				lex.putc(0.(i8))
			} else if sv == rnull {
				os.dief(
					"utils: sepc character -%s- literal should surround with single-quote ori:%s",
					ts,
					dstr
				)
			} else {
				ch<i8> = sv.data
				lex.putc(ch)
			}
		} else {
			lex.putc(c)
		}
		i += 1
	}
	return lex.dyn()
}
