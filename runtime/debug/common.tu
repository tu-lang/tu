use fmt
use os
use runtime
use string

// cfg(mod_static,true)

// Legacy DWARF path (disabled for formal backtrace).
lines<Lines> = null
elf<Elf>	 = null
// NOTICE: compiler may still set this for -g; table presence is the real gate.
enabled<i8>  = 0

func error(str){
	os.die(str)
}
func debug(str){
	fmt.println(str)
}
func check(ret<i32>){
	if ret == 0 {
		error("check  failed")
	}
}

// Bind .tupclntab if present; no fopen of the executable.
func debug_init(){
	pclntab_init()
}

// Resolve PC via pclntab; degrade to bare address when missing.
func findpc(pc<u64>){
	if pclntab_init() == 0.(i8) {
		return int(pc) + ":??"
	}
	return pcln_format_pc(pc)
}
