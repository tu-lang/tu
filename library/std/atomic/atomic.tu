func cas(addr<i32*>, old<i32>, newv<i32>)
func cas64(addr<i64*>, old<i64>, newv<i64>)
func store(addr<i32*> ,old<i32>,newv<i32>)
func store32(addr<i32*> ,old<i32>,newv<i32>){
	return store(addr,old,newv)
}
func store64(addr<u64*> ,old<u64>,newv<u64>)
func xchg (addr<i32*> , newv<i32>)
func xadd(addr<u32*> , newv<u32>)
func xadd64(addr<u64*> , newv<u64>)

func swap_i32(addr<i32*> , newv<i32>) {
	return xchg(addr,newv)
}
func load(ptr<u32*>) {
	return *ptr
}
func load64(ptr<u64*>){
	return *ptr
}
fn or8(ptr<i8*> , v<i8>)
