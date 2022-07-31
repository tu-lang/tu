
use fmt
use os
use net

mem Data {
	i8 a,b,c,d
}
// 1.结构体嵌套
mem InnerDirect{
	i8    a
	Data  inner
}
// 2.内嵌结构体指针
mem InnerPointer{
	i8     a
	Data*  inner
}
func test_inner_direct(){
	fmt.println("test_direct")
	var<InnerDirect> = new InnerDirect
	var2<Data> = var.inner
	var2.a = 10
	var2.b = 20
	var2.c = 30
	var2.d = 40
	// 内嵌结构体字段的访问：引用与无引用都是读取的地址
	p<Data> = &var.inner
	if  p.a != 10 || p.b != 20 || p.c != 30 || p.d != 40 {
		fmt.println("test inner1 failed")
		os.exit(-1)
	}
	// 测试下 引用访问和非引用访问
	if  var.inner != &var.inner {
		fmt.println("mem  field: & access and direct access  should equal")
		os.exit(-1)
	}
	fmt.println("test_direct success")
}

func test_inner_pointer(){
	fmt.println("test_pointer")
	var<InnerPointer> = new InnerPointer
	var2<Data> = new Data
	var.inner = var2
	if  var.inner != var2 {
		fmt.println("var.inner != var2 ")
		os.exit(-1)
	}
	var2.a = 10
	var2.b = 20
	var2.c = 30
	var2.d = 40
	p<Data> = var.inner
	if  p.a != 10 || p.b != 20 || p.c != 30 || p.d != 40 {
		fmt.println("test pointer failed")
		os.exit(-1)
	}
	// 测试下 引用访问和非引用访问
	if  var.inner == &var.inner {
		fmt.println("mem pointer field: & access and direct access not should equal")
		os.exit(-1)
	}
	fmt.println("test_pointer success")
}



func main(){
	test_inner_direct()
	test_inner_pointer()
	test_extern_direct()
	test_extern_pointer()
}

// 3.结构体嵌套
mem ExternDirect{
	i8    	  a
	net.Data  inner
}
// 4.内嵌结构体指针
mem ExternPointer{
	i8     a
	net.Data*  inner
}
func test_extern_direct(){
	fmt.println("test_extern_direct")
	var<ExternDirect> = new ExternDirect
	var2<net.Data> = var.inner
	var2.a = 10
	var2.b = 20
	var2.c = 30
	var2.d = 40
	// 内嵌结构体字段的访问：引用与无引用都是读取的地址
	p<net.Data> = &var.inner
	if  p.a != 10 || p.b != 20 || p.c != 30 || p.d != 40 {
		fmt.println("test inner1 failed")
		os.exit(-1)
	}
	// 测试下 引用访问和非引用访问
	if  var.inner != &var.inner {
		fmt.println("mem  field: & access and direct access  should equal")
		os.exit(-1)
	}
	fmt.println("test_extern_direct success")
}
func test_extern_pointer(){
	fmt.println("test_extern_pointer")
	var<ExternPointer> = new ExternPointer
	var2<net.Data> = new net.Data
	var.inner = var2
	if  var.inner != var2 {
		fmt.println("var.inner != var2 ")
		os.exit(-1)
	}
	var2.a = 10
	var2.b = 20
	var2.c = 30
	var2.d = 40
	p<net.Data> = var.inner
	if  p.a != 10 || p.b != 20 || p.c != 30 || p.d != 40 {
		fmt.println("test pointer failed")
		os.exit(-1)
	}
	// 测试下 引用访问和非引用访问
	if  var.inner == &var.inner {
		fmt.println("mem pointer field: & access and direct access not should equal")
		os.exit(-1)
	}
	fmt.println("test_extern_pointer success")
}