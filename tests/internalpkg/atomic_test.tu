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
mem CasI64{
	i64 before,i,after
}
True<i64> = 1
func test_compare_and_swap_i64(){
	x<CasI64> = new CasI64 {
		before : magic64,
		after : magic64
	}
	for val<i64> = 1 ; val + val > val; val += val {
		x.i = val
		if atomic.cas64(&x.i,val, val + 1) != True {
			os.dief("should have swapped %d %d", int(val), int(val+1))
		}
		if x.i != val + 1 {
			os.dief("wrong x.i after swap: x.i=%d val+1=%d", int(x.i), int(val+1))
		}
		x.i = val + 1
		if atomic.cas64(&x.i,val,val + 1) == True {
			os.dief("should not have swapped %d %d", int(val), int(val+2))
		}
		if x.i != val + 1 {
			os.dief("wrong x.i after swap: x.i=%d val+1=%d", int(x.i), int(val+1))
		}
	}
	if x.before != magic64 || x.after != magic64 {
		os.dief("wrong magic: %d _ %d != %d _ %d", int(x.before), int(x.after), int(magic64), int(magic64))
	}
	fmt.println("test comparse and swap i64 success")
}
func main(){
	test_swap_i32()
	test_compare_and_swap_i64()
}