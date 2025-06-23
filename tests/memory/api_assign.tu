fn main(){
	case1()
	case2()
	case3()
}
api ApiCase {
	fn case1(v1<i32>,v2<i32>){
		this.case2(v1,v2)
	}
	fn case2(v1<i32>,v2<i32>)
}
mem Case {
	i32 a
	i32 b
	ApiCase* c
	ApiCase* arr[3]
}
impl ApiCase for Case {
	fn case2(v1<i32>,v2<i32>) {
		if this.a == v1 {} else os.die("neq v1")
		if this.b == v2 {} else os.die("neq v2")
	}
}
Case::get() Case {
	return this
}
fn newCase(v1<i32>,v2<i32>) Case {
	return new Case {
		a: v1,
		b: v2,
	}
}
fn case() Case , Case ,Case,Case {
	return new Case{a: 1,b: 2},
		   new Case{a: 3,b: 4},
		   new Case{a: 5,b: 6},
		   new Case{a: 7,b: 8}
}

fn case3(){
	fmt.println("test multi assign over success")
	v1<ApiCase> = null
	m2<Case> = newCase(1,2)
	m3<Case> = newCase(3,4)
	m4<Case> = newCase(5,6)
	v5<ApiCase> = null
	//api receiver
	v1, m2.c , m3.get().arr[1] , m4.get().c,v5 = case()
	// origin
	p1<Case> = v1
	p2<Case> = m2.c
	p3<Case> = m3.get().arr[1]
	p4<Case> = m4.get().c
	//api call
	v1.case1(p1.a,p1.b)
	m2.c.case1(p2.a,p2.b)
	m3.get().arr[1].case1(p3.a,p3.b)
	m4.get().c.case1(p4.a,p4.b)


	fmt.println("test multi assign over success")
}


fn case2(){
	fmt.println("test multi assign missing")
		v1<ApiCase> = null
	m2<Case> = newCase(1,2)
	m3<Case> = newCase(3,4)
	//api receiver
	v1, m2.c , m3.get().arr[1]  = case()
	// origin
	p1<Case> = v1
	p2<Case> = m2.c
	p3<Case> = m3.get().arr[1]
	//api call
	v1.case1(p1.a,p1.b)
	m2.c.case1(p2.a,p2.b)
	m3.get().arr[1].case1(p3.a,p3.b)
	fmt.println("test multi assign missing success")
}

fn case1(){
	fmt.println("test multi assign return oop")
	v1<ApiCase> = null
	m2<Case> = newCase(1,2)
	m3<Case> = newCase(3,4)
	m4<Case> = newCase(5,6)
	//api receiver
	v1, m2.c , m3.get().arr[1] , m4.get().c = case()
	// origin
	p1<Case> = v1
	p2<Case> = m2.c
	p3<Case> = m3.get().arr[1]
	p4<Case> = m4.get().c
	//api call
	v1.case1(p1.a,p1.b)
	m2.c.case1(p2.a,p2.b)
	m3.get().arr[1].case1(p3.a,p3.b)
	m4.get().c.case1(p4.a,p4.b)

	fmt.println("test multi assign return oop success")
}

