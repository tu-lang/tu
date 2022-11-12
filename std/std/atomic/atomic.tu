func cas64(addr<i64*>, old<i64>, newv<i64>)
func xchg (addr<i32*> , newv<i32>)

func swap_i32(addr<i32*> , newv<i32>) {
	return xchg(addr,newv)
}