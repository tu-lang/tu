fn main(){
	case1()
	case2()
	case3()
	case4()
}
api ApiCase3 {
	fn case1(v1<i32>,v2<i32>){
		this.case2(v1,v2)
	}
	fn case2(v1<i32>,v2<i32>)
}
mem Case3 {
	i32 a
	i32 b
	Case3* c
	Case3* arr[3]
}
impl ApiCase3 for Case3 {
	fn case2(v1<i32>,v2<i32>) {
		if this.a == v1 {} else os.die("neq v1")
		if this.b == v2 {} else os.die("neq v2")
	}
}
Case3::get() Case3 {
	return this
}
fn newcase3(v1<i32>,v2<i32>) Case3 {
	return new Case3 {
		a: v1,
		b: v2,
	}
}
gcase3<Case3> = new Case3 {
	a: 3,
	b: 4
}
fn case3_1() ApiCase3,ApiCase3,ApiCase3,ApiCase3,ApiCase3,ApiCase3,ApiCase3 {
	v1<Case3> = newcase3(1,2)
	v3<Case3> = newcase3(5,6)
	v3.c = v3

	v4<Case3> = newcase3(7,8)
	v4.c = v4

	v5<Case3> = newcase3(9,10)
	v5.c = v5

	v6<Case3> = newcase3(11,12)
	v6.c = v6

	v7<Case3> = new Case3 {
		arr: [
			newcase3(13,14),
			newcase3(14,15),
			newcase3(16,17),
		]
	}
	return v1, &gcase3, v3.c , v4.get() , v5.get().c , v6.c.get() ,
			v7.arr[1]

}
fn case4_2() Case3 {
	return 0.(i8)
}
fn case4_1() ApiCase3 {
	return case4_2()
}
fn case4(){
	fmt.println("test null check")
	fmt.println("test null check success")
}

fn case3(){
	fmt.println("test multi assign return oop")
	v1<u64*>,v2<u64*>,v3<u64*>,v4<u64*>,v5<u64*>,v6<u64*>,v7<u64*> =
		case3_1()
	
	a1<ApiCase3> = v1
	a2<ApiCase3> = v2
	a3<ApiCase3> = v3
	a4<ApiCase3> = v4
	a5<ApiCase3> = v5
	a6<ApiCase3> = v6
	a7<ApiCase3> = v7
	m1<Case3> = v1
	m2<Case3> = v2
	m3<Case3> = v3
	m4<Case3> = v4
	m5<Case3> = v5
	m6<Case3> = v6
	m7<Case3> = v7

	a1.case1(m1.a,m1.b)
	a2.case1(m2.a,m2.b)
	a2.case1(m2.a,m2.b)
	a2.case1(m2.a,m2.b)
	a2.case1(m2.a,m2.b)
	a2.case1(m2.a,m2.b)
	a2.case1(m2.a,m2.b)

	fmt.println("test multi assign return oop success")
}

api ApiCase2 {
	fn case1(v1<i32>,v2<i32>){
		this.case2(v1,v2)
	}
	fn case2(v1<i32>,v2<i32>)
}
mem Case2 {
	ApiCase2* inner
	i32 a
	i32 b
	Case2* c
	Case2* arr[3]
}
impl ApiCase2 for Case2 {
	fn case2(v1<i32>,v2<i32>) {
		if this.a == v1 {} else os.die("neq v1")
		if this.b == v2 {} else os.die("neq v2")
	}
}
Case2::get() Case2 {
	return this
}
fn newcase2(v1<i32>, v2<i32>) Case2 {
	return new Case2 {
		a: v1,
		b: v2
	}
}
fn case2_1() ApiCase2 {
	v<Case2> = newcase2(1,2)
	v.c = v
	return v.c.get().c
}
fn case2_2() ApiCase2 {
	v<Case2> = newcase2(3,4)
	v.c = v
	return v.c.get().c.get()
}
fn case2_3() ApiCase2 {
	v<Case2> = new Case2 {
		arr: [
			newcase2(1,2),
			newcase2(3,4),
			newcase2(5,6),
		]
	}
	return v.arr[1]
}

fn case2(){
	fmt.println("test chainexpr complex return")
	//case1 structmember
	v1<u64*> = case2_1()
	a1<ApiCase2> = v1
	m1<Case2> = v1
	a1.case1(m1.a,m1.b)

	//case2 funcexpr
	v2<u64*> = case2_2()
	a2<ApiCase2> = v2
	m2<Case2> = v2
	a2.case1(m2.a,m2.b)

	//case3 arrayindex
	v3<u64*> = case2_3()
	a3<ApiCase2> = v3
	m3<Case2> = v3
	a3.case1(m3.a,m3.b)
	fmt.println("test chainexpr complex return success")
}

api ApiCase1 {
	fn case1(v1<i32>,v2<i32>){
		this.case2(v1,v2)
	}
	fn case2(v1<i32>,v2<i32>)
}
mem Case1 {
	ApiCase1* inner
	i32 a
	i32 b
	Case1* c
	ApiCase1* arr[3]
}
impl ApiCase1 for Case1 {
	fn case2(v1<i32>,v2<i32>) {
		if this.a == v1 {} else os.die("neq v1")
		if this.b == v2 {} else os.die("neq v2")
	}
}


fn case1_1() ApiCase1 {
	v<Case1> = new Case1 {
		a: 11,
		b: 22,
	}		
	return v
}
gv1<Case1:> = new Case1 {
	a: 33,
	b: 44,
}		
fn case1_2() ApiCase1 {
	return &gv1
}

fn case1_3() ApiCase1 {
	v<Case1> = new Case1 {
		a: 55,
		b: 66
	}
	v.c = v
	return v.c
}
fn case1_4_1() Case1 {
	return new Case1 {
		a: 77,
		b: 88,
	}
}
fn case1_4() ApiCase1 {
	return case1_4_1()
}
fn case1(){
	fmt.println("test return statement oop insert")
	//case 1 v
	v1<u64*> = case1_1()
	a1<ApiCase1> = v1
	m1<Case1> = v1
	a1.case1(m1.a,m1.b)

	//case 2 &
	v2<u64*> = case1_2()
	a2<ApiCase1> = v2
	m2<Case1> = v2
	a2.case1(m2.a,m2.b)

	//case 3 structmember
	v3<u64*> = case1_3()
	a3<ApiCase1> = v3
	m3<Case1> = v3
	a3.case1(m3.a,m3.b)

	//case4 funcexpr
	v4<u64*> = case1_4()
	a4<ApiCase1> = v4
	m4<Case1> = v4
	a4.case1(m4.a,m4.b)

	fmt.println("test return statement oop insert success")
}