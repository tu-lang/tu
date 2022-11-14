use std
use std.atomic
use os

magic32<i32> = 0xdedbeef
magic64<i64> = 0xdeddeadbeefbeef
mem LoadI64 {
	i64 before,i,after
}
func load_i64(){
	x<LoadI64> = new LoadI64 {
		before : magic64,
		after  : magic64
	}
	for delta<i64> = 1 ; delta + delta > delta ; delta += delta {
		k<i64> = atomic.load64(&x.i)
		if k != x.i {
			os.die("delta=%d i=%d k=%d", delta, x.i, k)
		}
		x.i += delta
	}
	if x.before != magic64 || x.after != magic64 {
		os.die("wrong magic: %#x _ %#x != %#x _ %#x", x.before, x.after, int(magic64), int(magic64))
	}
	fmt.println("load i64 success")
}
mem LoadU64 {
	u64 before , i , after
}
func load_u64(){
	x<LoadU64> = new LoadU64 {
		before : magic64 ,
		after  : magic64
	}
	for delta<u64> = 1 ; delta + delta > delta ; delta += delta {
		k<u64> = atomic.load64(&x.i)
		if k != x.i {
			os.die("delta=%d i=%d k=%d", delta, x.i, k)
		}
		x.i += delta
	}
	if x.before != magic64 || x.after != magic64 {
		os.die("wrong magic: %#x _ %#x != %#x _ %#x", x.before, x.after, int(magic64), int(magic64))
	}
	fmt.println("load u64 success")
}
mem LoadI32 {
	i32 before,i,after
}
func load_i32(){
	x<LoadI32> = new LoadI32 {
		before : magic32,
		after  : magic32
	}
	for delta<i32> = 1; delta+delta > delta; delta += delta {
		k<i32> = atomic.load(&x.i)
		if k != x.i {
			os.die("delta=%d i=%d k=%d", delta, x.i, k)
		}
		x.i += delta
	}
	if x.before != magic32 || x.after != magic32 {
		os.die("wrong magic: %#x _ %#x != %#x _ %#x", x.before, x.after, magic32, magic32)
	}
	fmt.println("load i32 success")
}
mem LoadU32 {
	u32 before,i,after
}
func load_u32(){
	x<LoadU32> = new LoadU32 {
		before : magic32,
		after  : magic32
	}
	for delta<u32> = 1; delta+delta > delta; delta += delta {
		k<u32> = atomic.load(&x.i)
		if k != x.i {
			os.die("delta=%d i=%d k=%d", delta, x.i, k)
		}
		x.i += delta
	}
	if x.before != magic32 || x.after != magic32 {
		os.die("wrong magic: %#x _ %#x != %#x _ %#x", x.before, x.after, magic32, magic32)
	}
	fmt.println("load u32 success")
}
func main(){
	load_i32()
	load_u32()
	load_i64()
	load_u64()
}