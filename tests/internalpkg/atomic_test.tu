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
mem Store32 {
	i32 before, i ,after
}
func test_store_i32(){
	x<Store32> = new Store32{
		before : magic32,
		after  : magic32
	}
	v<i32> = 0
	for delta<i32> = 1 ; delta + delta > delta; delta += delta {
		atomic.store(&x.i, v)
		if x.i != v {
			os.dief("delta=%d i=%d v=%d", int(delta), int(x.i), int(v))
		}
		v += delta
	}
	if x.before != magic32 || x.after != magic32 {
		os.dief("wrong magic: %d _ %d != %d _ %d", int(x.before), int(x.after), int(magic32), int(magic32))
	}
	fmt.println("store i32 success")
}
mem StoreI64 {
	i64 before,i,after
}
func test_store_i64(){
	x<StoreI64> = new StoreI64 {
		before : magic64,
		after : magic64
	}
	v<i64> = 0
	for delta<i64> = 1 ; delta+delta > delta; delta += delta {
		atomic.store64(&x.i,v)
		if x.i != v {
			os.dief("delta=%d i=%d v=%d", delta, x.i, v)
		}
		v += delta
	}
	if x.before != magic64 || x.after != magic64 {
		os.dief("wrong magic: %#x _ %#x != %#x _ %#x", x.before, x.after, int(magic64), int(magic64))
	}
	fmt.println("test store i64 success")
}
mem StoreU64 {
	u64 before,i,after
}
func test_store_u64(){
	x<StoreU64> = new StoreU64 {
		before: magic64,
		after : magic64
	}
	v<u64> = 0
	for delta<u64> = 1;  delta+delta > delta; delta += delta {
		atomic.store64(&x.i,v)
		if x.i != v {
			os.dief("delta=%d i=%d v=%d", delta, x.i, v)
		}
		v += delta
	}
	if x.before != magic64 || x.after != magic64 {
		os.dief("wrong magic: %#x _ %#x != %#x _ %#x", x.before, x.after, int(magic64), int(magic64))
	}
	fmt.println("test store_u64 success")
}

mem AddI32 {
	i32 before,i,after
}
func test_add_i32(){
	x<AddI32> = new AddI32 {
		before : magic32,
		after  : magic32
	}
	j<i32> = 0
	for delta<i32> = 1 ; delta+delta > delta; delta += delta {
		k<i32> = atomic.xadd(&x.i, delta)
		j += delta
		if x.i != j || k != j {
			os.dief("delta=%d i=%d j=%d k=%d", delta, x.i, j, k)
		}
	}
	if x.before != magic32 || x.after != magic32 {
		os.dief("wrong magic: %#x _ %#x != %#x _ %#x", x.before, x.after, magic32, magic32)
	}
	fmt.println("test xadd i32")
}

mem AddU32 {
	u32 before,i,after
}
func test_add_u32(){
	x<AddU32> = new AddU32 {
		before : magic32,
		after  : magic32
	}
	j<u32> = 0
	for delta<u32> = 0 ; delta+delta > delta; delta += delta {
		k<u32> = atomic.xadd(&x.i,delta)
		j += delta
		if x.i != j || k != j {
			os.dief("delta=%d i=%d j=%d k=%d", delta, x.i, j, k)
		}
	}
	if x.before != magic32 || x.after != magic32 {
		os.dief("wrong magic: %#x _ %#x != %#x _ %#x", x.before, x.after, magic32, magic32)
	}
	fmt.println("test xadd u32 success")
}
mem AddI64 {
	i64 before,i,after
}
func test_add_i64(){
	x<AddI64> = new AddI64 {
		before : magic64,
		after  : magic64
	}
	j<i64> = 0
	for delta<i64> = 1 ; delta+delta > delta; delta += delta {
		k<i64> = atomic.xadd64(&x.i,delta)
		j += delta
		if x.i != j || k != j {
			os.dief("delta=%d i=%d j=%d k=%d", delta, x.i, j, k)
		}
	}
	if x.before != magic64 || x.after != magic64 {
		os.dief("wrong magic: %#x _ %#x != %#x _ %#x", x.before, x.after, int(magic64), int(magic64))
	}
	fmt.println("test xadd 64 success")
}
mem AddU64 {
	u64 before,i,after
}
func test_add_u64(){
	x<AddU64> = new AddU64 {
		before : magic64,
		after  : magic64
	}
	j<u64> = 0
	for delta<u64> = 1; delta+delta > delta; delta += delta {
		k<u64> = atomic.xadd64(&x.i,delta)
		j += delta
		if x.i != j || k != j {
			os.dief("delta=%d i=%d j=%d k=%d", delta, x.i, j, k)
		}
	}
	if x.before != magic64 || x.after != magic64 {
		os.dief("wrong magic: %#x _ %#x != %#x _ %#x", x.before, x.after, int(magic64), int(magic64))
	}
	fmt.println("test xadd u64 success")
}

mem CasI32 {
	i32 before,i,after
}
func test_cas_i32(){
	x<CasI32> = new CasI32 {
		before : magic32,
		after  : magic32
	}
	for val<i32> = 1 ; val + val > val ; val += val {
		x.i = val
		if atomic.cas(&x.i,val,val + 1) != True {
			os.dief("should have swapped %#x %#x", val, val+1)
		}
		if x.i != val + 1 {
			os.dief("wrong x.i after swap: x.i=%#x val+1=%#x", x.i, val+1)
		}
		x.i = val + 1
		if atomic.cas(&x.i,val,val + 2) == True {
			os.dief("should not have swapped %#x %#x", val, val+2)
		}
		if x.i != val+1 {
			os.dief("wrong x.i after swap: x.i=%#x val+1=%#x", x.i, val+1)
		}
	}
	if x.before != magic32 || x.after != magic32 {
		os.dief("wrong magic: %#x _ %#x != %#x _ %#x", x.before, x.after, magic32, magic32)
	}
	fmt.println("test cas i32 succes")
}
mem CasU32 {
	u32 before,i,after
}
func test_cas_u32(){
	x<CasU32> = new CasU32{
		before : magic32,
		after : magic32
	}
	for val<u32> = 1 ; val + val > val ; val += val {
		x.i = val
		if atomic.cas(&x.i,val, val + 1) != True {
			os.dief("should have swapped %#x %#x", val, val+1)
		}
		if x.i != val+1 {
			os.dief("wrong x.i after swap: x.i=%#x val+1=%#x", x.i, val+1)
		}
		x.i = val + 1
		if atomic.cas(&x.i,val,val + 2) == True {
			os.dief("should not have swapped %#x %#x", val, val+2)
		}
		if x.i != val+1 {
			os.dief("wrong x.i after swap: x.i=%#x val+1=%#x", x.i, val+1)
		}
	}
	if x.before != magic32 || x.after != magic32 {
		os.dief("wrong magic: %#x _ %#x != %#x _ %#x", x.before, x.after, magic32, magic32)
	}
	fmt.println("test case u32 success")
}

func main(){
	test_swap_i32()
	test_compare_and_swap_i64()
	test_cas_i32()
	test_cas_u32()
	test_store_i32()
	test_store_i64()
	test_store_u64()
	test_add_i32()
	test_add_u32()
	test_add_i64()
	test_add_u64()
}