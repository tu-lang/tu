use std.atomic
use fmt
use os

magic32<i32> = 0xdedbeef
magic64<i64> = 0xdeddeadbeefbeef

mem SwapI32 {
	i32 before,i,after
}
func test_swap_i32(){
	x<SwapI32> = new SwapI32 {
		before : magic32,
		after  : magic32
	}
	j<i32> = 0
	for delta<i32> = 1 ; delta + delta > delta; delta += delta {
		k<i32> = atomic.swap_i32(&x.i, delta)
		if x.i != delta || k != j {
			os.dief(
				"delta=%d i=%d j=%d k=%d",
				int(delta),int(x.i),int(j),int(k)
			)
		}
		j = delta
	}
	if x.before != magic32 || x.after != magic32 {
		os.dief(
			"wrong magic: %d %d %d %d",
			int(x.before),int(x.after),int(magic32),int(magic32)
		)
	}	
	fmt.println("test swap i32 success")
}
func main(){
	test_swap_i32()
}