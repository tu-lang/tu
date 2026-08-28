fn cas(addr<i32*>, old<i32>, newv<i32>)
fn cas64(addr<i64*>, old<i64>, newv<i64>)
fn store(addr<i32*> ,old<i32>,newv<i32>)
fn store32(addr<i32*> ,old<i32>,newv<i32>){
	return store(addr,old,newv)
}
fn store64(addr<u64*> ,old<u64>,newv<u64>)
fn xchg (addr<i32*> , newv<i32>)
fn xadd(addr<u32*> , newv<u32>)
fn xadd64(addr<u64*> , newv<u64>)

fn swap_i32(addr<i32*> , newv<i32>) {
	return xchg(addr,newv)
}
fn load(ptr<u32*>) {
	return *ptr
}
fn load64(ptr<u64*>){
	return *ptr
}
fn or8(ptr<i8*> , v<i8>)
