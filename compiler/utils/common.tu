use std
use runtime
use string
use fmt
use os

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
	if std.exist("PWD",envs) {
		return envs["PWD"]
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

// Parent directory; no slash → "."
func path_dirname(path){
	n = std.len(path)
	if n == 0 return "."
	i = n - 1
	while i >= 0 {
		if path[i] == '/' break
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
		if path[i] == '/' break
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
	if last == '/'
		return d + f
	return d + "/" + f
}

func make_tu_build_dir(stem){
	tmp = "/tmp"
	if std.exist("TMPDIR",envs) && envs["TMPDIR"] != "" {
		tmp = envs["TMPDIR"]
	}
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
		// pid + ntime + rand：std.rand 
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
		os.shell("mkdir '" + dir + "'")
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
			os.shell("mkdir -p '" + explicit_dir + "'")
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