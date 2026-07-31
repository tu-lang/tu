use os
use std
use fmt
use apicross
use memret_owner

fn main(){
	case1()
	case2()
	case3()
	case4()
	case_cross_pkg()
	case_cross_pkg_mem_return()
	case_member_tyassert()
	case_tyassert_dispatch()
	case_u64_tyassert_dispatch()
	case_api_ptr_field_dispatch()
	case_assign_repeat_dispatch()
}

// Local tyassert on concrete mem must hit api vtable (not default stub).
api Counter {
	fn get() i32 {
		return 0
	}
}
mem Inc {
	i32 v
}
impl Counter for Inc {
	fn get() i32 {
		return this.v
	}
}
fn case_tyassert_dispatch(){
	fmt.println("test tyassert api dispatch")
	i<Inc> = new Inc { v: 99 }
	n<i32> = i.(Counter).get()
	if n != 99 os.die("tyassert api dispatch expected 99 from impl, got default stub")
	fmt.println("test tyassert api dispatch success")
}

// u64 opaque heap bits + .(Api) must dispatch impl (vptr from assign/new).
fn case_u64_tyassert_dispatch(){
	fmt.println("test u64 tyassert api dispatch")
	inc<Inc> = new Inc { v: 42 }
	bits<u64> = inc
	n<i32> = bits.(Counter).get()
	if n != 42 os.die("u64 tyassert api dispatch expected 42 from impl")
	fmt.println("test u64 tyassert api dispatch success")
}

// Api* field one-line call must dispatch without rewriting outer holder vptr.
mem ApiPtrHold {
	Counter* inner
}
fn case_api_ptr_field_dispatch(){
	fmt.println("test api ptr field dispatch")
	inc<Inc> = new Inc { v: 77 }
	h<ApiPtrHold> = new ApiPtrHold { inner: inc }
	n<i32> = h.inner.get()
	if n != 77 os.die("api ptr field dispatch expected impl value")
	fmt.println("test api ptr field dispatch success")
}

// Assign/new binds vptr once; repeated calls stay on impl.
fn case_assign_repeat_dispatch(){
	fmt.println("test assign api repeat dispatch")
	c<Counter> = new Inc { v: 11 }
	n1<i32> = c.get()
	n2<i32> = c.get()
	if n1 != 11 || n2 != 11 os.die("repeat api dispatch after assign expected stable impl")
	fmt.println("test assign api repeat dispatch success")
}

// Chain + tyassert + api member call (h.w.(WriteApi).write) must hit impl vtable.
api WriteApi {
	fn write() i32 {
		return 0
	}
}
mem Writer {
	i32 n
}
impl WriteApi for Writer {
	fn write() i32 {
		return this.n
	}
}
mem Holder {
	Writer* w
}
fn case_member_tyassert(){
	fmt.println("test member tyassert api dispatch")
	h<Holder> = new Holder { w: new Writer { n: 55 } }
	v<i32> = h.w.(WriteApi).write()
	if v != 55 os.die("member tyassert api dispatch expected impl")
	fmt.println("test member tyassert api dispatch success")
}

api ApiCase4 {
	fn case1(v1<i32>,v2<f32>,v3<i8*>){
		this.case2(v1,v2,v3)
	}
	fn case2(v1<i32>,v2<f32>,v3<i8*>)
}

mem Case4 {
	i32 a
	f32 b
}
impl ApiCase4 for Case4 {
	fn case2(v1<i32>, v2<f32>,v3<i8*>){
		if v1 == this.a {} else os.die("neq v1")
		if v2 == this.b {} else os.die("neq v2")
	}
}

fn case4(){
	fmt.println("test implict oop")
	p<Case4> = new Case4{
		a: 11,
		b: 22
	}
	p.case1(p.a,p.b)
	fmt.println("test implict oop success")
}

api ApiCase3 {
	fn case1(v1<i32>,v2<f32>,v3<i8*>){
		this.case2(v1,v2,v3)
	}
	fn case2(v1<i32>,v2<f32>,v3<i8*>)
}
mem Case3 {
	i32 a
	f32 b
	i8* c
	Case3* arr[2]
	Case3* inner
}
impl ApiCase3 for Case3 {
	fn case2(v1<i32>, v2<f32>,v3<i8*>){
		if v1 == this.a {} else os.die("neq v1")
		if v2 == this.b {} else os.die("neq v2")
		if std.memcmp(v3,this.c,std.strlen(this.c)) == 0 {} else {
			os.die("neq v3")
		}
	}
}
Case3::get() Case3 {
	return this
}
fn case3_2(p1<ApiCase3>,p2<ApiCase3>,p3<ApiCase3>,p4<ApiCase3>){
	v1<Case3> = p1
	v2<Case3> = p2
	v3<Case3> = p3
	v4<Case3> = p4
	p1.case1(v1.a,v1.b,v1.c)
	fmt.println("case1 success")
	p2.case1(v2.a,v2.b,v2.c)
	fmt.println("case2 success")
	p3.case1(v3.a,v3.b,v3.c)
	fmt.println("case3 success")
	p4.case1(v4.a,v4.b,v4.c)
	fmt.println("case4 success")
}
fn newcase3(v1<i32>,v2<i32>,v3<i8*>) Case3 {
	return new Case3 {
		a: v1,
		b: v2 ,
		c: v3,
	}
}
fn case3(){
	fmt.println("test pass impl api struct complex")
	//case1 func
	p1<Case3> = newcase3(11,12.34,"case3")
	//case2 func
	p2<Case3> = newcase3(22,32.34,"case32")
	p2.inner = p2
	//case3 member
	p3<Case3> = newcase3(31,42.34,"case33")
	p3.inner = p3
	//case4 arrayindex
	p4<Case3> = new Case3 {
		arr: [
			newcase3(51,62.34,"case34"),
			newcase3(51,62.34,"case35")
		]
	}
	case3_2(p1.get(),p2.inner.get(),p3.get().inner,p4.get().arr[1])
	fmt.println("test pass impl api struct complex success")
}




api ApiCase2 {
	fn case1(v1<i32>,v2<f32>,v3<i8*>){
		this.case2(v1,v2,v3)
	}
	fn case2(v1<i32>,v2<f32>,v3<i8*>)
}
mem Case2 {
	i32 a
	f32 b
	i8* c
	Case2* inner
}
impl ApiCase2 for Case2 {
	fn case2(v1<i32>, v2<f32>,v3<i8*>){
		if v1 == this.a {} else os.die("neq v1")
		if v2 == this.b {} else os.die("neq v2")
		if std.memcmp(v3,this.c,std.strlen(this.c)) == 0 {} else {
			os.die("neq v3")
		}
	}
}
fn case2_2(p1<ApiCase2>,p2<ApiCase2>,p3<ApiCase2>,p4<ApiCase2>){
	v1<Case2> = p1
	v2<Case2> = p2
	v3<Case2> = p3
	v4<Case2> = p4
	p1.case1(v1.a,v1.b,v1.c)
	fmt.println("case1 success")
	p2.case1(v2.a,v2.b,v2.c)
	fmt.println("case2 success")
	p3.case1(v3.a,v3.b,v3.c)
	fmt.println("case3 success")
	p4.case1(v4.a,v4.b,v4.c)
	fmt.println("case4 success")
}
fn case2_1() Case2 {
	return new Case2 {
		a: 77,
		b: 88.88,
		c: "case4"
	}
}

fn case2(){
	fmt.println("test pass impl api struct")
	//case1 var
	v1<Case2> = new Case2 {
		a : 11,
		b : 22.22,
		c : "case1"
	}
	//case2 ref
	v2<Case2:> = null
	v2.a = 33
	v2.b = 44.44
	v2.c = "case3"
	//case3 structmember
	v3<Case2> = new Case2 {
		a : 55,
		b : 66.66,
		c : "case3"
	}
	v3.inner = v3
	//case4 funcexpr
	case2_2(v1,&v2,v3.inner,case2_1())
	fmt.println("test pass impl api struct success")
}

fn passcast(v1<i8>,v2<f32>,v3<i32>,v4<f64>,v5<i8*>){
	fmt.println(int(v1))
	if v1 == -127 {} else os.die(
		os.die("neq -127")
	)
	if v2 >= 22.30 && v2 <= 22.40 {} else os.die(
		"neq 22.33"
	)
	if v3 == 123456 {} else os.die(
		"neq 123456"
	)
	if v4 >= 789.653 && v4 <= 789.655 {} else os.die(
		"neq 789.654"
	)
	if std.memcmp(v5,"passcast",8) == 0 {} else {
		os.die("neq passcast")
	}
}


fn case1(){
	fmt.println("test pass args cast")
	passcast(129,22.33,123456,789.654,"passcast")
	fmt.println("test pass args cast success")
}
// Cross-package api impl (apicross.CrossApi). Empty order_funcs snapshot used
// to emit apitl with no .quad and null vtable dispatch. Uses a test-local
// package so we do not drag library/sys (and its use net / sys/net.tu).
mem CrossFd {
	i32 fd
}
impl apicross.CrossApi for CrossFd {
	fn get_fd() i32 {
		return this.fd
	}
}
fn case_cross_pkg(){
	fmt.println("test cross-pkg api impl")
	f<CrossFd> = new CrossFd {
		fd: 9
	}
	a<apicross.CrossApi> = f
	if a.get_fd() != 9 os.die("cross-pkg api vtable empty")
	fmt.println("test cross-pkg api impl success")
}

// Cross-package (i32, Mem) multi-return must preserve pointer fields
// (pkg fn + Type::method; TcpStream::from_netio shape). Owner: memret_owner/.
fn case_cross_pkg_mem_return(){
	fmt.println("test cross-pkg mem multi-return")
	err<i32>, head<memret_owner.Box> = memret_owner.make_linked(7)
	if err != 1 os.die("make_linked err")
	if head == null os.die("head null")
	if head.tag != 7 os.die("head.tag")
	if head.next == null os.die("head.next null after cross-pkg multi-return")
	// Direct two-level chain (nested-pkg getType must resolve Box* → Box).
	if head.next.tag != 8 os.die("head.next.tag chain")
	n<memret_owner.Box> = head.next
	if n.tag != 8 os.die("head.next.tag")

	err2<i32>, h2<memret_owner.Box> = memret_owner.Box::make_linked(11)
	if err2 != 1 os.die("Box::make_linked err")
	if h2 == null os.die("head null Type::method")
	if h2.tag != 11 os.die("Type::method tag")
	if h2.next == null os.die("Type::method next null")
	if h2.next.tag != 12 os.die("Type::method next.tag chain")
	n2<memret_owner.Box> = h2.next
	if n2.tag != 12 os.die("Type::method next.tag")
	if h2.pe == null os.die("Type::method pe null")
	if h2.pe.tag != 111 os.die("Type::method pe.tag")
	fmt.println("test cross-pkg mem multi-return success")
}
