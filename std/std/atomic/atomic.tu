func cas64(addr<i64*>, old<i64>, newv<i64>)
func store32(addr<i32*> ,old<i32>,newv<i32>)
func xchg (addr<i32*> , newv<i32>)

func swap_i32(addr<i32*> , newv<i32>) {
	return xchg(addr,newv)
}
func load(ptr<u32*>) {
	return *ptr
}
func load64(ptr<u64*>){
	return *ptr
}
