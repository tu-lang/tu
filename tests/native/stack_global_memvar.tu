use fmt
use os
use pkg

mem T2 {
	i8  a
	i32 b
	i64 c
}
T2::test(){
	if this.b  == 22 {} else os.die("this.b == 22")
	fmt.println("test t2 success")
}
mem T1 {
	i32 a
	i64 b[3]
	T2* c
	T2  d
}

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
T1::test(){
	if this.a == 1 {} else os.die("this.a == 1")
	if this.b[0] == 31 {} else os.die("this.b[0] == 31")
	if this.b[1] == 32 {} else os.die("this.b[1] == 32")
	if this.b[2] == 33 {} else os.die("this.b[2] == 33")

	if this.d.a == 11 {} else os.die("this.d.a == 11")
	if this.d.b == 22 {} else os.die("this.d.a == 22")
	if this.d.c == 33 {} else os.die("this.d.a == 33")
	
	//test overflow
	this.b[3] = 35
	if this.c == 35 {} else os.die("this.c == 34")
	//test t2
	fmt.println("T1::test success")
	this.d.test()
}
func test_global_stack_structvar(){
	if gvar.a == 1 {} else os.die("gvar.a == 1")
	if gvar.b[0] == 31 {} else os.die("gvar.b[0] == 31")
	if gvar.b[1] == 32 {} else os.die("gvar.b[1] == 32")
	if gvar.b[2] == 33 {} else os.die("gvar.b[2] == 33")
	if gvar.c == 3 {} else os.die("gvar.c == 3")

	if gvar.d.a == 11 {} else os.die("gvar.d.a == 11")
	if gvar.d.b == 22 {} else os.die("gvar.d.a == 22")
	if gvar.d.c == 33 {} else os.die("gvar.d.a == 33")
	
	//test overflow
	gvar.b[3] = 34
	if gvar.c == 34 {} else os.die("gvar.c == 34")
	//test t1 inner func	
	fmt.println("test_global_stack_structvar success")
	gvar.test()
}
func test_extern_global_stack_structvar(){
	//chain expression
	if pkg.gvar.a == 1 {} else os.die("pkg.gvar.a == 1")
	if pkg.gvar.b[0] == 31 {} else os.die("pkg.gvar.b[0] == 31")
	if pkg.gvar.b[1] == 32 {} else os.die("pkg.gvar.b[1] == 32")
	if pkg.gvar.b[2] == 33 {} else os.die("pkg.gvar.b[2] == 33")
	if pkg.gvar.c == 3 {} else os.die("pkg.gvar.c == 3")

	if pkg.gvar.d.a == 11 {} else os.die("pkg.gvar.d.a == 11")
	if pkg.gvar.d.b == 22 {} else os.die("pkg.gvar.d.a == 22")
	if pkg.gvar.d.c == 33 {} else os.die("pkg.gvar.d.a == 33")
	
	//test overflow
	pkg.gvar.b[3] = 34
	if pkg.gvar.c == 34 {} else os.die("pkg.gvar.c == 34")
	
	fmt.println("test_extern_global_stack_structvar success")
	pkg.gvar.test()
}
func main(){
	test_global_stack_structvar()
	test_extern_global_stack_structvar()
}