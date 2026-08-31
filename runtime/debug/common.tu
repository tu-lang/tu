use fmt
use os
use runtime
use string


// Legacy DWARF path (disabled for formal backtrace).
lines<Lines> = null
elf<Elf>	 = null
// NOTICE: compiler may still set this for -g; table presence is the real gate.
enabled<i8>  = 0

fn error(str){
	os.die(str)
}
fn debug(str){
	fmt.println(str)
}
fn check(ret<i32>){
	if ret == 0 {
		error("check  failed")
	}
}

// Bind .tupclntab if present; no fopen of the executable.
fn debug_init(){
	pclntab_init()
}

// Resolve PC via pclntab; degrade to bare address when missing.
fn findpc(pc<u64>){
	if pclntab_init() == 0.(i8) {
		return int(pc) + ":??"
	}
	return pcln_format_pc(pc)
}
