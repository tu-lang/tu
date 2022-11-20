use os
use fmt
use t //测试外部全局静态变量

ga<u16:64> = [
        0, 1, 2, 7, 3, 13, 8, 19,
        4, 25, 14, 28, 9, 34, 20, 40,
        5, 17, 26, 38, 15, 46, 29, 48,
        10, 31, 35, 54, 21, 50, 41, 57,
        63, 6, 12, 18, 24, 27, 33, 39,
        16, 37, 45, 47, 30, 53, 49, 56,
        62, 11, 23, 32, 36, 44, 52, 55,
        61, 22, 43, 51, 60, 42, 59, 58,
]
func test_var(){
	ga[14] = 111 
	if ga[14] == 111 {} else os.die("ga[14] != 111")
	if ga[0] == 0 {} else os.die("ga[0] != 0")
	if ga[1] == 1 {} else os.die("ga[1] != 1")
	if ga[7] == 19 {} else os.die("ga[7] != 19")
	if ga[15] == 40 {} else os.die("ga[15] != 40")
	if ga[39] == 39 {} else os.die("ga[39] != 39")
	if ga[55] == 55 {} else os.die("ga[55] != 55")

	fmt.println("test_var success")
}
func test_var_ref(t<u16*>){
	t[14] = 222 
	if t[14] == 222 {} else os.die("t[14] != 222")
	if t[0] == 0 {} else os.die("t[0] != 0")
	if t[1] == 1 {} else os.die("t[1] != 1")
	if t[7] == 19 {} else os.die("t[7] != 19")
	if t[15] == 40 {} else os.die("t[15] != 40")
	if t[39] == 39 {} else os.die("t[39] != 39")
	if t[55] == 55 {} else os.die("t[55] != 55")
	fmt.println("test_var_ref success")
}
func test_extern_global(){
	t.ge[14] = 333 
	if t.ge[14] == 333 {} else os.die("t.ge[14] != 333")
	if t.ge[0] == 0 {} else os.die("t.ge[0] != 0")
	if t.ge[1] == 1 {} else os.die("t.ge[1] != 1")
	if t.ge[7] == 19 {} else os.die("t.ge[7] != 19")
	if t.ge[15] == 40 {} else os.die("t.ge[15] != 40")
	if t.ge[39] == 39 {} else os.die("t.ge[39] != 39")
	if t.ge[55] == 55 {} else os.die("t.ge[55] != 55")
	fmt.println("test_var extern global success")
}
mem B {
	i32 a,b
}
B::test(c<i32>){
	if this.b == c {} else os.die("this.c != c")	
	fmt.println("test B::test success")
}
mem A {
	B*  arr[2]
	i32 a,b
}
//写入二进制内
t2<A:> = new A {
	a : 11,
	b : 12
}
func test2(){
	//测试栈变量
	//测试结构体成员 是结构体数组的情况
	t2.arr[0] = new B{b:21}
	if t2.arr[0].b == 21 {} else os.die("t2.arr[0].b == 21")
	if t2.a == 11 {} else os.die("t2.a == 11")
	t2.arr[0].test(21.(i8))

	pt2<A:> = null //分配到栈上
	pt2.arr[0] = new B{a:30,b:100}
	pt2.a = 31
	pt2.b = 32
	if pt2.arr[0].a == 30 {} else os.die("pt2.arr[0].a == 30")
	if pt2.b == 32 {} else os.die("pt2.b == 32")
	pt2.arr[0].test(100.(i8))
	fmt.println("test2 success")
}

func main(){
	test_var()
	test_var_ref(&ga)
	test_extern_global()
	test2()
}