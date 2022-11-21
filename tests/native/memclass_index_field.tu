use fmt


mem Test {
	i64 a,b
	Inner inner
}
mem Inner {
	i32 a,b
	i8  c,d
	i8  f[3]
	i64 e
}
Test::test_arr(){
	if this.inner.f[0] == 9 {} else 
		os.die("this.inner.f[0] != 9")
	if this.inner.f[1] == 5 {} else 
		os.die("this.inner.f[1] != 5")
	if this.inner.f[2] == 2 {} else 
		os.die("this.inner.f[1] != 5")
	
	this.inner.d = 33
	this.inner.e = 44

	this.inner.f[0] = 99
	this.inner.f[1] = 55
	this.inner.f[2] = 22
	if this.inner.f[0] == 99 {} else 
		os.die("this.inner.f[0] != 99")
	if this.inner.f[1] == 55 {} else 
		os.die("this.inner.f[1] != 55")
	if this.inner.f[2] == 22 {} else 
		os.die("this.inner.f[2] != 22")

	if this.inner.d == 33 {} else os.die("this.inner.d != 33")
	if this.inner.e == 44 {} else os.die("this.inner.e != 44")
	return this.inner.f[2]
}
func test_chain_index(){
	var<Test> = new Test {
		inner: Inner {
			f : [9,5,2]
		}
	}
	ret<i8> = var.test_arr()
	if ret == 22 {} else os.die("ret != 22")
	fmt.println("test_chain index success")
}

mem B {
	i8 a 
	i16 b
	i64 c
	i32 d
}
mem A {
	i8  a
	B   b[2]
	i16  c
}
B::testa(){
	if this.a == 11 && this.b == 22 && this.c == 33 && this.d == 44 {} else {
		os.die("something wrong at B::testa")
	}
	fmt.println("B::testa success")
}
B::testb(){
	if this.a == 55 && this.b == 66 && this.c == 77 && this.d == 88 {} else {
		os.die("something wrong at B::testb")
	}
	fmt.println("B::testb success")
}
p<A:>  = new A{
	a : 100,
	b : [{11,22,33,44},{55,66,77,88}],
	c : 200
}

func test_stack_field_index(){
	if p.a == 100 {} else {
		os.die("p.a == 100")
	}	
	if p.c == 200 {} else {
		os.die("p.c == 200")
	}
	if p.b[0].a == 11 {} else os.die("p.b[0].a == 11")
	if p.b[0].b == 22 {} else os.die("p.b[0].b == 22")
	if p.b[1].a == 55 {} else os.die("p.b[1].a == 55")
	if p.b[1].b == 66 {} else os.die("p.b[1].b == 66")
	fmt.println("test stack field_index")

	p.b[0].testa()
	p.b[1].testb()
}
func main(){
	test_chain_index()

	test_stack_field_index()
}
