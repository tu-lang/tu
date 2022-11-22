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
//测试静态变量的field地址引用
use fmt
use std

mem B {
    i8 a
    i16 b
    i64 c
    i32 d
}
mem A {
	i8 before
    B free
    B next
    B current
	i8 after
}
A::testa(p<B>){
	if this.before == 33 && this.after != 444 {} else {
		os.die("this.before == 333 && this.after == 444")
	}
	if p.a == 1 && p.b == 2 && p.c == 3 && p.d == 4 {} else {
		os.die("test a failed")
	}
	fmt.println("test a success")
}
A::testb(p<B>){
	if this.before == 33 && this.after != 444 {} else {
		os.die("this.before == 333 && this.after == 444")
	}
	if p.a == 5 && p.b == 6 && p.c == 7 && p.d == 8 {} else {
		os.die("test b failed")
	}
	fmt.println("test b success")
}
A::testc(p<B>){
	if this.before == 33 && this.after != 444 {} else {
		os.die("this.before == 333 && this.after == 444")
	}
	if p.a == 9 && p.b == 10 && p.c == 11 && p.d == 12 {} else {
		os.die("test c failed")
	}
	fmt.println("test c success")
}
G<A:> = new A{
	before : 33,
	free : B{ a:1,b:2,c:3,d:4},
	next : B{ a:5,b:6,c:7,d:8},
	current : B{a:9,b:10,c:11,d:12},
	after: 444
}
func test_stack_addr(){
	G.testa(&G.free)
	G.testb(&G.next)
	G.testc(&G.current)
	fmt.println("test stack addr success")
}

mem RetT{
	u64 a,b
	u8  c[2000]
}
RetT::f1(){
	return &this.c[100]
}
RetT::test_return(){
	p<u8*> = &this.c[100]
	if p == this.f1() {} else {
		os.die("p != this.f1()")
	}
	fmt.println("test return success")
}
gret<RetT:>
func main(){
	test_global_stack_structvar()
	pkg2.test()
	test_stack_addr()
	gret.test_return()
}