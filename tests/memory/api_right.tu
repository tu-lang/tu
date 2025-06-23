use string


fn main(){
	case1()
	case2()
	case3()
}

api ApiCase3{
	fn case1(v1<i32>,v2<f32>,v3<string.String>,v4<f32>) i32 {
		return this.case2(v1,v2,v3,v4)
	}
	fn case2(v1<i32>,v2<f32>,v3<string.String>,v4<f32>) (i32)
}
mem Case3 {
	i32 a
	f32 b
	string.String* c
	f32 d
}
Case3::get() Case3 {
	return this
}
impl ApiCase3 for Case3 {
	fn case2(v1<i32>,v2<f32>,v3<string.String>,v4<f32>) i32 {
		if this.a == v1 {} else os.die("neq v1")
		v2_l<f32> = this.b - 0.1
		v2_h<f32> = this.b + 0.1
		if v2 >= v2_l && v2 <= v2_h {} else {
			os.die("neq v2")
		}
		str = this.c.dyn()
		if v3.dyn() == str {} else {
			os.die("neq v3")
		}
		v4_l<f32> = this.d - 0.1
		v4_h<f32> = this.d + 0.1
		if v4 >= v4_l && v4 <= v4_h {} else {
			os.die("neq v4")
		}
		return true
	}
}

fn case3_1() Case3 {
	return new Case3 {
		a: 7,
		b: 8.8,
		c: string.S(*"p1"),
		d: 9.9
	}
}
mem Case3_1 {
	Case3  v1
	Case3* v2
}

mem Case3_2 {
	Case3* arr1
	Case3* arr2[3]
	Case3  arr3[3]
}
mem Case3_3 {
	Case3_2* inner
}

fn case3(){
	fmt.println("case3 test right complex expression oop")
	//case 1 funcexpr
	p1<ApiCase3> = case3_1()
	p1mem<Case3> = p1
	p1.case1(p1mem.a,p1mem.b,p1mem.c,p1mem.d)

	//case2 structmember
	p2<Case3_1> = new Case3_1 {
		v1 : Case3 {
			a: 7,
			b: 8.8,
			c: string.S(*"p1"),
			d: 9.9
		},
		v2 : case3_1()
	}
	p2api<ApiCase3> = &p2.v1	// stack
	p2api.case1(p2.v1.a,p2.v1.b,p2.v1.c,p2.v1.d)

	p2api = p2.v2	
	p2api.case1(p2.v2.a,p2.v2.b,p2.v2.c,p2.v2.d)

	//case3 arry index
	arr1<i32> = sizeof(Case3) * 3
	p3<Case3_2> = new Case3_2 {
		arr1: new arr1,
		arr2: [
			case3_1(),
			case3_1(),
			case3_1()
		],
	} 
	p3.arr1[2].a = 311
	p3.arr1[2].b = 311.311
	p3.arr1[2].c = string.S(*"p2")
	p3.arr1[2].d = 53.53

	p3.arr3[1].a = 31
	p3.arr3[1].b = 31.31
	p3.arr3[1].c = string.S(*"p2")
	p3.arr3[1].d = 42.42

	p3api<ApiCase3> = p3.arr1[2]    // arrayindex(strucmember) -> structmember
	p3api.case1(p3.arr1[2].a,p3.arr1[2].b,p3.arr1[2].c,p3.arr1[2].d)

	p3api = p3.arr2[1]
	p3api.case1(p3.arr2[1].a,p3.arr2[1].b,p3.arr2[1].c,p3.arr2[1].d)

	p3api = p3.arr3[1]
	p3api.case1(p3.arr3[1].a,p3.arr3[1].b,p3.arr3[1].c,p3.arr3[1].d)

	//case4 complex chainexpr
	p4<Case3_3> = new Case3_3 {
		inner: p3
	}
	//func
	p4api<ApiCase3> = p4.inner.arr2[2].get()
	p4api.case1(
		p4.inner.arr2[2].a,
		p3.arr2[2].b,
		p4.inner.arr2[2].c,
		p3.arr2[2].d
	)
	//member
	p3.arr1[0].a = 611
	p3.arr1[0].b = 611.611
	p3.arr1[0].c = string.S(*"p2")
	p3.arr1[0].d = 711.711

	p4api = p4.inner.arr1
	p4api.case1(
		p4.inner.arr1[0].a,
		p3.arr1.b,
		p4.inner.arr1[0].c,
		p3.arr1.d
	)

	//arrayindex
	p4api = p4.inner.arr1[2]    // arrayindex(strucmember) -> structmember
	p4api.case1(
		p3.arr1[2].a,p4.inner.arr1[2].b,p3.arr1[2].c,p4.inner.arr1[2].d
	)

	p4api = p4.inner.arr2[1]
	p4api.case1(
		p3.arr2[1].a,p4.inner.arr2[1].b,p4.inner.arr2[1].c,p3.arr2[1].d
	)

	p4api = p4.inner.arr3[1]
	p4api.case1(
		p4.inner.arr3[1].a,p4.inner.arr3[1].b,p3.arr3[1].c,p3.arr3[1].d
	)

	fmt.println("test case3 right complex expression oop success")
}



api ApiCase2 {
	fn case1(v1<i32>,v2<f32>,v3<string.String>,v4<f32>) i32 {
		return this.case2(v1,v2,v3,v4)
	}
	fn case2(v1<i32>,v2<f32>,v3<string.String>,v4<f32>) (i32)
}
mem Case2{
	i32 a
	f32 b
	string.String* c
	f32 d
}
impl ApiCase2 for Case2 {
	fn case2(v1<i32>,v2<f32>,v3<string.String>,v4<f32>) i32 {
		if this.a == v1 {} else os.die("neq v1")
		v2_l<f32> = this.b - 0.1
		v2_h<f32> = this.b + 0.1
		if v2 >= v2_l && v2 <= v2_h {} else {
			os.die("neq v2")
		}
		//OPTIMIZE: dyn expression
		// if v3.dyn() == this.c.dyn() {} else {
		str = this.c.dyn()
		if v3.dyn() == str {} else {
			os.die("neq v3")
		}
		v4_l<f32> = this.d - 0.1
		v4_h<f32> = this.d + 0.1
		if v4 >= v4_l && v4 <= v4_h {} else {
			os.die("neq v4")
		}
		return true
	}
}
gcase2_1<ApiCase2> = new Case2{
	a: 1,
	b: 2.2,
	c: string.S(*"gcase2_1"),
	d: 3.3
}
gcase2_2<Case2> = new Case2{
	a: 1,
	b: 2.2,
	c: string.S(*"gcase2_1"),
	d: 3.3
}
gcase2_3<Case2:> = new Case2{
	a: 4,
	b: 5.5,
	// c: string.S(*"gcase2_2"),
	d: 6.6
}

fn case2(){
	fmt.println("test case2 base op")
	p1<Case2> = new Case2 {
		a: 7,
		b: 8.8,
		c: string.S(*"p1"),
		d: 9.9
	}
	//case1
	api1<ApiCase2> = p1
	api1.case1(p1.a,p1.b,p1.c,p1.d)

	//case2
	p2<Case2:> = null
	p2.a = 10
	p2.b = 11.11
	p2.c = string.S(*"p2")
	p2.d = 12.12
	api2<ApiCase2> = &p2
	api2.case1(p2.a,p2.b,p2.c,p2.d)

	//case3
	g1<Case2> = gcase2_1
	gcase2_1.case1(g1.a,g1.b,g1.c,g1.d)
	g2<ApiCase2> = g1
	g2.case1(g1.a,g1.b,g1.c,g1.d)

	g3<ApiCase2> = gcase2_2
	g3.case1(gcase2_2.a,gcase2_2.b,gcase2_2.c,gcase2_2.d)

	//case4
	gcase2_3.c = string.S(*"gcase2_3")
	g4<ApiCase2> = &gcase2_3
	g4.case1(gcase2_3.a,gcase2_3.b,gcase2_3.c,gcase2_3.d)

	fmt.println("test case2 base op success")
}


mem VirBase {
	u64 pointer
}
api ApiCase1 {
	fn case1() i32 {
		return this.case2()
	}
	fn case2() (i32)
}
api ApiCase1_1 {
	fn case3() i32 {
		return this.case4()
	}
	fn case4() (i32)
}
mem Case1 {
}
Case1::t1() i32 {
	return 11
}
impl ApiCase1 for Case1 {
	fn case2() i32 {
		return 22
	}
}
impl ApiCase1_1 for Case1 {
	fn case4() i32 {
		return 33
	}
}
gcase1_1<Case1> = new Case1{}
gcase1_2<Case1:> = new Case1{}
//测试隐式转换,自动嵌入虚表指针
fn case1(){
	fmt.println("test case 1")
	if sizeof(Case1) == 8 {} else os.die("neq 8")
	//case1 local 
	p<Case1> = new Case1{}
	if p.case1() == 22 {} else {
		os.die("neq 22")
	}
	if p.t1() == 11 {} else os.die("neq 11")
	//case2 local stack
	p2<Case1:> = null
	if p2.case1() == 22 {} else {
		os.die("neq 22-2")
	}
	if p2.t1() == 11 {} else os.die("neq 11-2")

	//case 3 global 
	if gcase1_1.case1() == 22 {} else {
		os.die("neq 22-3")
	}
	if gcase1_1.t1() == 11 {} else os.die("neq 11-3")

	//case 4 global stack
	if gcase1_2.case1() == 22 {} else {
		os.die("neq 22-4")
	}
	if gcase1_2.t1() == 11 {} else os.die("neq 11-4")

	//case 5 multi impl
	if p.case3() == 33 {} else os.die("neq 33")

	fmt.println("test case 1 success")
}