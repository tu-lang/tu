use std
use std.map
use runtime
use string
use fmt
use os

// i32 map/array presence for mem/static typed compares.
// Arg order matches std.exist / std.contains: (key, map_or_array).
fn map_has(key, m) i32 {
	if m == null {
		return 0
	}
	mv<runtime.Value> = m
	if mv.type == runtime.Map {
		hit<u64> = map.map_find(mv, key)
		if hit != 0.(u64) {
			return 1
		}
		return 0
	}
	if mv.type == runtime.Array {
		if runtime.array_in(key, mv.data) == runtime.True {
			return 1
		}
		return 0
	}
	return 0
}

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

func char1(cn<i8>){
    return runtime.newobject(runtime.Char,cn)
}
func hash(data){
	return int(runtime.get_hash_key(data))
}
// func ALIGN_DOWN(x<u64>,a<u64>) {
func ALIGN_DOWN(x,a) {
	return ALIGN_UP(x - a + 1,a)
}
// func ALIGN_UP(x<u64> , a<u64>) {
func ALIGN_UP(x , a) {
	return ( x + (a - 1) ) & ( ~ (a - 1))
}
func max(l<i32>,r<i32>){
	if l > r return l
	return r
}
func pwd(){
	if is_windows_host() {
		buf<i8*> = new 260
		n<i32> = os.win_getcwd(buf, 260.(i32))
		if n > 0 {
			return norm_slash(string.new(buf))
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
	bs = char1(92.(i8))
	if c == bs {
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
			int(std.ntime()),
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
	fmt.printf("[tu] workdir: %s\n", workdir)
}

specs = {
	"\\n"  : 10.(i8),
	"\\\\" : 92.(i8),
	"\\t"  : 9.(i8),
	"\\\'" : 39.(i8),
	"\\\"" : 34.(i8),
	"\\b"  : 8.(i8),
	"\\r"  : 13.(i8),
	"\\f"  : 12.(i8),
	"\\0"  : 0.(i8),
	"\\r"  : 13.(i8),
	"\\v"  : 11.(i8)
}
func getescapestr(dstr<runtime.Value>){
	str<string.Str> = dstr.data
	i<i32>  = 0
	total<i32> = str.len()
	p<i8*> = str
	//NOTICE: unstable ,compiler do this
	Null<u64> = &runtime.internal_null

	lex<string.String> = string.emptyS()
	while i < total {
		c<i8> = p[i]
        if c == '\\' {
			ts = "\\"
            i += 1
			c = p[i]
            ts += char1(c)
			if ts == "\\0" {
				lex.putc(0.(i8))
			}
            else if specs[ts] == Null {
				os.dief(
                    "utils: sepc character -%s- literal should surround with single-quote ori:%s",
					ts,
					dstr
                )
            }else{
				lex.putc(specs[ts])
			}
        }else{
			lex.putc(c)
        }
        i += 1
    }
	return lex.dyn()
}