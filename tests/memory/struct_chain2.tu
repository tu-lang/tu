
use fmt
use os

mem Info {
	i8  a
	u8  b
	i8* c
}
mem User {
	i8    a
	Info* i
}
mem Base {
	i8    a
	User* u
}
func newBase(){
	var<Base> = new Base
	var.u = new User
	var.u.i = new Info
	return var
}
// 1. 函数传参数测试
func test_args(){
	fmt.println("test_args")
	f = func(a<i8>,b<i8>){
		if  a != 10 {
			fmt.println("a != 10")
			os.exit(-1)
		}
		if  b != 20 {
			fmt.println("b != 20")
			os.exit(-1)
		}
		fmt.println(int(a),int(b))
	}
	var<Base> = newBase()
	var.u.a = 10
	var.u.i.a = 20
	// push args
	f(var.u.a,var.u.i.a)
	fmt.println("test_args success")
}

// 2. 操作符测试
func test_op(){
	fmt.println("test operator")

	var<Base> = newBase()
	var.u.a = 10	
	var.u.i.a = 20
	if  var.u.a != 10 {
		fmt.println("var.u.a != 10")
		os.exit(-1)	
	}
	if  20 != var.u.i.a {
		fmt.println("20 != var.u.a")
		os.exit(-1)	
	}
	var.u.a += 10
	if  var.u.a != var.u.i.a {
		fmt.println("var.u.a != var.u.i.a")
		os.exit(-1)	
	}
	fmt.println("test operator success")
}

//3. builtin-func 参数返回值也需要测试
func test_builtinfunc(){
	fmt.println("test builtinnfunc")
	var<Base> = newBase()

	var.u.i.a = 100
	fmt.println(int(var.u.i.a))
	if   int(var.u.i.a)  != 100 {
		fmt.println("var.u.i.a should eq 100")
		os.exit(-1)
	}
	fmt.println("test builtinnfunc success")
}

//4. return  的时候也需要考虑到load
func test_return(){
	fmt.println("test return")
	
	f = func(var<Base>){
		var.u.a = 99
		var.u.i.a = 99
		return var.u.a
	}
	var<Base> = newBase()
	ret<i16> = f(var)
	if  var.u.a != var.u.i.a {
		fmt.println("var.u.a should eq var.u.i.a")
		os.exit(-1)
	}
	if   int(ret)  != 99 {
		fmt.println("ret should eq 99")
		os.exit(-1)
	}
	fmt.println("test return success")
}
// 5. delref 解除引用的测试
func test_delref(){
	fmt.println("test delref")
	var<Base> = newBase()
	var.u.i.c = new 8
	*var.u.i.c = 100
	if  *var.u.i.c != 100 {
		fmt.println("*var.u.i.c should eq 100")
		os.exit(-1)
	}
	fmt.println("test delref success")
}
// 6. &引用测试
func test_ref(){
	fmt.println("test ref")
	var<Base> = newBase()
	// 测试内嵌结构体指针访问的时候 &与不&都是不相等的
	l<u64> = var.u.i
	r<u64> = &var.u.i
	if  l == r {
		fmt.println("l should not eq r")
		os.exit(-1)
	}
	if  var.u.i == &var.u.i {
		fmt.println("var.u.i should not eq &var.u.i")
		os.exit(-1)
	}
	p<i8*> = &var.u.i.a
	*p = 120
	if  var.u.i.a != 120 {
		fmt.println("var.u.i.a should eq 120")
		os.exit(-1)
	}
	p = var.u.i
	if  p != &var.u.i.a {
		fmt.println("var.u.i.a should eq p")
		os.exit(-1)
	}
	*p = 80
	if  var.u.i.a != 80 {
		fmt.println("var.u.i.a should eq 130")
		os.exit(-1)
	}
	p2<u8*> = &var.u.i.b
	*p2 = 140
	if  var.u.i.b != 140 {
		fmt.println("var.u.i.a should eq 140")
		os.exit(-1)
	}
	f = func(l<u64>,r<u64>){
		if  l == r {
			fmt.println("var.u.i should not eq &var.u.i")
			os.exit(-1)
		}
	}
	f(var.u.i,&var.u.i)
	fmt.println("test ref success")
}
func main(){
	test_args()
	test_op()
	test_builtinfunc()
	test_return()
	test_delref()
	test_ref()
}