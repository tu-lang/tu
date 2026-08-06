// Phase1–3 pclntab: findpc, dense line at call site, capture truncate, degrade.
use fmt
use os
use std
use string
use runtime.debug as debug

fn pcln_probe_target(){
	return 1
}

fn pcln_nested_inner(){
	return 2
}

fn pcln_nested_outer(){
	return pcln_nested_inner()
}

// Caller line must be this call site, not function start.
fn pcln_line_leaf(){
	frames = debug.stack(8)
	if std.len(frames) < 2 {
		os.die("pclntab: need caller frame")
	}
	return frames[1]
}

fn pcln_line_caller(){
	x = 1
	s = pcln_line_leaf()
	return s
}

fn pcln_walk_leaf(){
	frames = debug.stack(8)
	n = std.len(frames)
	if n < 2 {
		os.die("pclntab: stack walk too short: " + n)
	}
	i = 0
	while i < n {
		s = frames[i]
		if s == null || std.len(s) < 2 {
			os.die("pclntab: empty stack frame at " + i)
		}
		i += 1
	}
	return frames
}

fn main(){
	debug.debug_init()
	pc<u64> = pcln_probe_target.(u64)
	s = debug.findpc(pc)
	fmt.println("findpc:", s)
	if std.len(s) < 4 {
		os.die("pclntab: findpc result too short: " + s)
	}
	if s == int(pc) + ":??" {
		os.die("pclntab: table empty or miss for probe target: " + s)
	}

	pc2<u64> = pcln_nested_inner.(u64)
	s2 = debug.findpc(pc2)
	if s2 == int(pc2) + ":??" {
		os.die("pclntab: miss nested inner: " + s2)
	}

	frames = pcln_walk_leaf()
	fmt.println("stack frames:", std.len(frames))

	// Dense line: caller frame must be call site, not function start
	cs = pcln_line_caller()
	fmt.println("caller frame:", cs)
	if std.len(cs) < 4 {
		os.die("pclntab: caller frame too short: " + cs)
	}
	// Call site is `s = pcln_line_leaf()` → dense line :31
	expect_tail = ":31"
	got_start_tail = ":29"
	tail3 = string.sub(cs, std.len(cs) - 3)
	if tail3 != expect_tail {
		os.die("pclntab: expected dense line ending " + expect_tail + " got: " + cs)
	}
	if has_substr(cs, got_start_tail) && tail3 != expect_tail {
		os.die("pclntab: still function start only: " + cs)
	}

	n<i32>, trunc<i32>, pc0<u64> = debug.capture_stack_probe(16)
	if n < 2 {
		os.die("pclntab: capture_stack_probe too short: " + n)
	}
	if pc0 == 0.(u64) {
		os.die("pclntab: capture_stack_probe empty pc")
	}
	n2<i32>, trunc2<i32>, pc1<u64> = debug.capture_stack_probe(1)
	if n2 != 1 {
		os.die("pclntab: expected 1 frame got " + n2)
	}
	if trunc2 != 1 {
		os.die("pclntab: expected truncated=1")
	}

	bad<u64> = 1.(u64)
	sb = debug.findpc(bad)
	expect = int(bad) + ":??"
	if sb != expect {
		os.die("pclntab: expected degrade '" + expect + "' got '" + sb + "'")
	}

	fmt.println("pclntab_backtrace ok")
}

fn has_substr(s, sub){
	n<i32> = std.len(s)
	m<i32> = std.len(sub)
	if m == 0 {
		return true
	}
	if m > n {
		return false
	}
	i<i32> = 0
	while i <= n - m {
		// sub + s[i+m..] == s[i..]  ⇒  s[i..] starts with sub
		if sub + string.sub(s, i + m) == string.sub(s, i) {
			return true
		}
		i += 1
	}
	return false
}
