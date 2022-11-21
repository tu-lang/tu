use fmt
use os
use pkg2

mem T2 {
	i8  a
	i32 b
	i64 c
}
mem T1 {
	i32 a
	i64 b[3]
	T2* c
	T2  d
}
//编译器写到二进制文件中，非main初始化后自动init
gvar<T1:> = new T1 {
	a : 1,
	b : [31,32,33],
	c : 3,
	d : T2 {
		a : 11,
		b : 22,
		c : 33
	}
}
func test_global_stack_structvar(){
	p<T1> = &gvar //栈地址引用
	if p.a == 1 {} else os.die("p.a == 1")
	if p.b[0] == 31 {} else os.die("p.b[0] == 31")
	if p.b[1] == 32 {} else os.die("p.b[1] == 32")
	if p.b[2] == 33 {} else os.die("p.b[2] == 33")
	if p.c == 3 {} else os.die("p.c == 3")

	if p.d.a == 11 {} else os.die("p.d.a == 11")
	if p.d.b == 22 {} else os.die("p.d.a == 22")
	if p.d.c == 33 {} else os.die("p.d.a == 33")
	
	//test overflow
	p.b[3] = 34
	if p.c == 34 {} else os.die("p.c == 34")
	
	fmt.println("test_global_stack_structvar success")
}
func main(){
	test_global_stack_structvar()
	pkg2.test()
}