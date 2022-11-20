use fmt
use os

mem Inner{
	i32 a 
	i32 b
}
mem Test {
	i32 a
	i32 b,c
	i8*   arr8
	i16*  arr16
	i32*  arr32
	i64*  arr64
	i32   stack[3]
	Inner inner
}
//TODO:
func test_arr_multi(){
	var<Test> = default_test()
	var.arr64 = new i64[2]
	var.arr64[0] = new i64[2]
	var.arr64[1] = new i64[2]
	//test
	//var.arr64[0][0] = 1
	//var.arr64[0][1] = 2
	//var.arr64[1][0] = 3
	//var.arr64[1][1] = 4
	//if var.arr64[0][0] != 1 os.die("var.arr64[0][0] != 1")
	//if var.arr64[0][1] != 2 os.die("var.arr64[0][1] != 2")
	//if var.arr64[1][0] != 3 os.die("var.arr64[1][0] != 3")
	//if var.arr64[1][1] != 4 os.die("var.arr64[1][1] != 4")
	
	fmt.println("test arr mulit success")
}
func test_arr(){
	var<Test> = default_test()
	var.arr32 = new i32[3]
	//stack arr
	var.stack[0] = 100
	var.stack[1] = 200
	var.stack[2] = 300
	//heap arr
	var.arr32[0] = 222
	var.arr32[1] = 333
	var.arr32[2] = 444
	if var.stack[0] != 100 os.die("var.stack[0] != 100")
	if var.stack[1] != 200 os.die("var.stack[1] != 200")
	if var.stack[2] != 300 os.die("var.stack[2] != 300")
	if var.arr32[0] != 222 os.die("var.arr32[0] != 222")
	if var.arr32[1] != 333 os.die("var.arr32[1] != 333")
	if var.arr32[2] != 444 os.die("var.arr32[2] != 444")
	fmt.println("test arr success")
}
func default_test(){
	//在解析这里的时候可能还没有解析Test结构体
	//新增一个初始化表达式 Expression，这样就可以递归了
	var<Test> = new Test {
		a : 10, //表达式赋值
		b : 20, //表达式赋值
		arr8: new i8[2],  //表达式赋值
		stack: [1,2,3],  //表达式赋值
		inner: Inner {  //初始化表达式 这种只能在new Test这边来判断了
			a: 33,
			b: 44,
		}
	}
	if var.a != 10 os.die("var.a != 10")
	if var.b != 20 os.die("var.b != 20")
	if var.c != 0 os.die("var.c != 10")
	if var.arr8 == 0 os.die("var.arr8 == 0")
	if var.stack[0] != 1 os.die("var.stack[0] != 1")
	if var.stack[2] != 3 os.die("var.stack[2] != 3")
	if var.inner.a != 33 os.die("var.inner.a != 33")
	if var.inner.b != 44 os.die("var.inner.a != 44")

	fmt.println("test default struct init success")
	return var
}
func main(){
	default_test()
	test_arr()
	//TODO: 
	// test_arr_multi()
}