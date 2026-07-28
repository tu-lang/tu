
use fmt
use os

mem Header{
	i8*  a
	u8   b
	i16* c
	u16  d
	i32* e
	u32  f
	i64* g
	u64  h
}

// Owner with field pointer getter — nested call as arg must keep full pointer width.
mem PtrOwner {
	i8 data[8]
}
PtrOwner::data_ptr() i8* {
	return &this.data[0]
}

fn take_i8(p<i8*>, n<u64>) i8* {
	return p
}

fn pkg_data_ptr(o<PtrOwner>) i8* {
	return &o.data[0]
}

// Nested mem method / package fn returning i8* as call arg (no movsxd trunc).
fn test_nested_ptr_arg() {
	fmt.println("test nested pointer call arg")
	o<PtrOwner> = new PtrOwner
	o.data[0] = 11.(i8)
	o.data[1] = 22.(i8)

	// Member call nested as first arg
	p1<i8*> = take_i8(o.data_ptr(), 8)
	if *p1 != 11.(i8) {
		fmt.println("member nested arg bad", int(*p1))
		os.exit(-1)
	}
	*p1 = 33.(i8)
	if o.data[0] != 33.(i8) {
		fmt.println("member nested write-back bad")
		os.exit(-1)
	}

	// Package fn nested as first arg
	o.data[0] = 44.(i8)
	p2<i8*> = take_i8(pkg_data_ptr(o), 8)
	if *p2 != 44.(i8) {
		fmt.println("pkg nested arg bad", int(*p2))
		os.exit(-1)
	}
	*p2 = 55.(i8)
	if o.data[0] != 55.(i8) {
		fmt.println("pkg nested write-back bad")
		os.exit(-1)
	}

	// Local binding still works (control)
	t<i8*> = o.data_ptr()
	p3<i8*> = take_i8(t, 8)
	if p3 != t {
		fmt.println("local bind path mismatch")
		os.exit(-1)
	}
	fmt.println("test nested pointer call arg success")
}
// 测试一下指针的读写
func test_assign(p<Header>)
{
	fmt.println("test mem pointer member assign")
	p.a = &p.b
	p.c = &p.d
	p.e = &p.f
	p.g = &p.h

	p.b = 100
	p.d = 200
	p.f = 300
	p.h = 400

	if   int(p.b)  != 100 {
		fmt.println("p.b != 100",int(p.b))
		os.exit(-1)
	}
	if   int(p.d)  != 200 {
		fmt.println("p.d != 200",int(p.d))
		os.exit(-1)
	}
	if   int(p.f)  != 300 {
		fmt.println("p.f != 300",int(p.f))
		os.exit(-1)
	}
	if   int(p.h)  != 400 {
		fmt.println("p.h != 400",int(p.h))
		os.exit(-1)
	}
	fmt.println("test mem pointer member success")
}
func test_read(p<Header>){
	fmt.println("test mem pointer member read")

	if   int(*p.a)  != 100 {
		fmt.println("*p.a != 100",int(*p.a))
		os.exit(-1)
	}
	if   int(*p.c)  != 200 {
		fmt.println("*p.c != 200",int(*p.c))
		os.exit(-1)
	}
	if   int(*p.e)  != 300 {
		fmt.println("*p.e != 300",int(*p.e))
		os.exit(-1)
	}
	if   int(*p.g)  != 400 {
		fmt.println("*p.g != 400",int(*p.g))
		os.exit(-1)
	}
	fmt.println("test mem pointer member read success")
}
func test_var(p<Header>)
{
	// a,c,e,g
	p.h = -100
	a<i8*> = p.g
	if   int(*a)  != -100 {
		fmt.println("*a<i8> != -100",int(*a))
		os.exit(-1)
	}
	p.h = -100000
	b<i64*> = p.g
	if   int(*b)  != -100000 {
		fmt.println("*b<i64> != -100000",int(*b))
		os.exit(-1)
	}
	fmt.println("test var del ref  cast success")
}
func main(){
	test_nested_ptr_arg()
	p<Header> = new Header
	test_assign(p)
	test_read(p)
	test_var(p)
	fmt.println(p.a,int(p.b),p.c,int(p.d),p.e,int(p.f),p.g,int(p.h))
}