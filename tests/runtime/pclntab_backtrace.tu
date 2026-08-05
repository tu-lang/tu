// Phase1–3 pclntab: findpc, stack walk, capture_stack truncate, unknown-PC degrade.
use fmt
use os
use std
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
	// Reject bare "addr:??" degradation for a known function entry
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
	top = frames[0]
	if std.len(top) < 4 {
		os.die("pclntab: walk top frame too short: " + top)
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
	if pc1 == 0.(u64) {
		os.die("pclntab: truncated capture empty pc")
	}

	// Unknown PC must degrade without abort
	bad<u64> = 1.(u64)
	sb = debug.findpc(bad)
	expect = int(bad) + ":??"
	if sb != expect {
		os.die("pclntab: expected degrade '" + expect + "' got '" + sb + "'")
	}

	fmt.println("pclntab_backtrace ok")
}
