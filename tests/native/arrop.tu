use fmt
use os
use std
use string


func arr_overflow(){
	_p<i64:2> = 0
	p2<i64>  = 133
	p<i64*> = &_p
	p[0] = 12
	if p[0] != 12 os.die("p[0] != 12") 
	p[1] = 13 
	if p[1] != 13 os.die("p[0] != 13")
	//overflow
	if p2 != 133  os.die("p2 != 133")
	//test outbound
	p[2] = 14
	if p[2] != 14 os.die("p[2] != 14")
	if p2 != 14 os.die("p2 != 14")

	fmt.println("test arr_overflow success")
}
func arr_overflow_var(){
	_p<i64:2> = 0
	p2<i64>  = 133
	p<i64*> = &_p
	zero<i8> = 0  one<i8> = 1  two<i8> = 2
	p[zero] = 12
	if p[zero] != 12 os.die("p[0] != 12") 
	p[one] = 13 
	if p[one] != 13 os.die("p[0] != 13")
	//overflow
	if p2 != 133  os.die("p2 != 133")
	//test outbound
	p[two] = 14
	if p[two] != 14 os.die("p[2] != 14")
	if p2 != 14 os.die("p2 != 14")

	fmt.println("test arr_overflow success")
}
func new_test(){
	arri8<i8*> = new i8[2]
	arri32<i32*> = new i32[2]
	arri64<i64*> = new i64[2]
	arri8[0] = 1
	arri8[1] = 2
	arri32[0] = 3
	arri32[1] = 4
	arri64[0] = 5
	arri64[1] = 6

	if arri8[0] != 1 os.die("arri8[0] != 1")
	if arri8[1] != 2 os.die("arri8[1] != 2")
	if arri32[0] != 3 os.die("arri32[0] != 3")
	if arri32[1] != 4  os.die("arri32[1] != 4")
	if arri64[0] != 5 os.die("arri64[0] != 5")
	if arri64[1] != 6 os.die("arri64[1] != 6")
	fmt.println("new test success")
}
func arr_op(){
	//new [3]u64 8(u64) * 3 = 24 bytes
	_arr32<i32:2> = null
	arr32<i32*> = &_arr32
	_arr8<i8:2> = null
	arr8<i8*> = &_arr8
	_arr64<i64:2> = null
	arr64<i64*> = &_arr64
	_arr16<i16:2> = null
	arr16<i16*> = &_arr16
	//op
	arr64[0] = 64641
	arr64[1] = 64642
	arr16[0] = 16161
	arr16[1] = 16162
	arr32[0] = 32321
	arr32[1] = 32322
	arr8[0] = 1
	arr8[1] = 2
	if arr8[0] != 1 os.die("arr8[0] != 1")
	if arr8[1] != 2 os.die("arr8[1] != 2")
	if arr32[0] != 32321 os.die("arr32[0] != 32321")
	if arr32[1] != 32322 os.die("arr32[1] != 32322")
	if arr64[0] != 64641 os.die("arr64[0] != 64641")
	if arr64[1] != 64642 os.die("arr64[1] != 364642")
	if arr16[0] != 16161 os.die("arr16[0] != 16161")
	if arr16[1] != 16162 os.die("arr16[1] != 16162")

	fmt.println("test arr op success")
}
//TODO:
func test_arr_multi(){
	arr64<i64*> = new i64[2]
	arr64[0] = new i64[2]
	arr64[1] = new i64[2]
	//test
	//arr64[0][0] = 1
	//arr64[0][1] = 2
	//arr64[1][0] = 3
	//arr64[1][1] = 4
	//if arr64[0][0] != 1 os.die("var.arr64[0][0] != 1")
	//if arr64[0][1] != 2 os.die("var.arr64[0][1] != 2")
	//if arr64[1][0] != 3 os.die("var.arr64[1][0] != 3")
	//if arr64[1][1] != 4 os.die("var.arr64[1][1] != 4")
	
	fmt.println("test arr mulit success")
}
func test_chain(){
	fmt.println("test arr chain")
	arr<std.Array> = std.NewArray() 
	s1<string.String> = string.S(*"test1dsf")
	s2<string.String> = string.S(*"3333333-ssdfsdf")
	arr.push(s1)
	if arr.addr[0].(string.String).len() == s1.len()  {} else {
		os.die("arr.addr[0].(string.String).len() != s1.len")
	}
	arr.push(s2)
	if arr.addr[1].(string.String).len() == s2.len()  {} else {
		os.die("arr.addr[1].(string.String).len() != s1.len")
	}
	fmt.println(
		int(
			arr.addr[0].(string.String).len()
		)
	)
	
	fmt.println("test arr chain success")
}
func main(){
	arr_overflow()
	arr_overflow_var()
	arr_op()
	new_test()
	test_chain()
	//TODO: support multi layer index 
	// test_arr_multi()
	fmt.println("arrop test success")
}
