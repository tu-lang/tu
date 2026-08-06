// Phase3: framesize present on PclnRec for pcsp subset walk.

use fmt
use os
use runtime
use runtime.debug

fn pcsp_probe_leaf(){
	return 1
}

fn pcsp_probe_mid(){
	return pcsp_probe_leaf()
}

fn test_framesize_nonzero(){
	fmt.println("test_framesize_nonzero")
	debug.pclntab_init()
	pc<u64> = pcsp_probe_mid.(u64)
	r = debug.findfunc(pc)
	if r == null {
		os.die("findfunc miss for probe")
	}
	if r.framesize < 16 {
		os.die("framesize too small")
	}
	fmt.println("test_framesize_nonzero passed")
}

fn test_capture_still_works(){
	fmt.println("test_capture_still_works")
	n, trunc, pc0 = debug.capture_stack_probe(8)
	if n < 1 {
		os.die("capture empty")
	}
	fmt.println("test_capture_still_works passed")
}

fn main(){
	test_framesize_nonzero()
	test_capture_still_works()
	fmt.println("all pcsp tests passed")
}
