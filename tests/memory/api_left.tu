fn main(){
	case4()
	case3()
	case2()
	case1()
}

api ApiCase4 {
	fn case1(v1<i32>,v2<i32>){
		this.case2(v1,v2)
	}
	fn case2(v1<i32>,v2<i32>)
}
mem Case4 {
	Case4* inner
	i32 a,b
	ApiCase4* c
	ApiCase4* arr[3]
}
Case4::get() Case4 { return this}
impl ApiCase4 for Case4 {
	fn case2(v1<i32>,v2<i32>) {
		if this.a == v1 {} else os.die("neq v1")
		if this.b == v2 {} else os.die("neq v2")
	}
}
gcase4<Case4> = null
fn case4_1(v1<i32>,v2<i32>) Case4 {
	gcase4 = new Case4 {
		a: v1,
		b: v2
	}
	return gcase4
}

fn case4(){
	fmt.println("test chain complex expression")
	//case1 array
	p<Case4> = new Case4{
		inner: new Case4 {
			a: 11,
			b: 22
		}
	}
	p.inner.arr[1] = p.inner
	p.inner.arr[1].case1(p.inner.a,p.inner.b)

	//case2 
	p = new Case4 {
		inner: new Case4 {
			a: 33,
			b: 44
		}
	}
	p.inner.get().c = p.inner
	p.inner.get().c.case1(p.inner.a,p.inner.b)

	//case3 
	case4_1().c = gcase4
	gcase4.c.case1(gcase4.a,gcase4.b)
	

	fmt.println("test chain complex expression success")
}


api ApiCase3 {
	fn case1(v1<i32>,v2<i32>){
		this.case2(v1,v2)
	}
	fn case2(v1<i32>,v2<i32>)
}
mem Case3 {
	ApiCase3* inner
	i32 a,b
	Case3* c
}
impl ApiCase3 for Case3 {
	fn case2(v1<i32>,v2<i32>) {
		if this.a == v1 {} else os.die("neq v1")
		if this.b == v2 {} else os.die("neq v2")
	}
}

fn case3(){
	fmt.println("test chain expression")
	p<Case3> = new Case3{
		c: new Case3 {
			a: 11,
			b: 22
		}
	}
	p.c.inner = p.c
	p.c.case1(p.c.a,p.c.b)

	fmt.println("test chain expression success")
}

api ApiCase2 {
	fn case1(v1<i32>,v2<i32>){
		this.case2(v1,v2)
	}
	fn case2(v1<i32>,v2<i32>)
}
mem Case2 {
	ApiCase2* inner
	i32 a,b
}
impl ApiCase2 for Case2 {
	fn case2(v1<i32>,v2<i32>) {
		if this.a == v1 {} else os.die("neq v1")
		if this.b == v2 {} else os.die("neq v2")
	}
}

fn case2(){
	fmt.println("test structmember")
	p<Case2> = new Case2{
		a: 11,
		b: 22,
	}
	p.inner = p
	p.inner.case1(p.a,p.b)
	fmt.println("test structmember success")
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
		if this.a == v1 {} else {
			fmt.println(int(this.a),int(v1))
			os.die(
				"neq v1"
			)
		}
		if this.b == v2 {} else os.die(
			"neq v2"
		)
	}
}
Case1::get() Case1 {
	return this
}
fn newcase1(v1<i32>,v2<i32>) Case1{
	return new Case1 {
		a: v1,
		b: v2
	}
}

// new struct 
fn case1(){
	fmt.println("test struct inner api")
	//case1  var
	p1<Case1> = new Case1 {a: 11,b: 22}
	p2<Case1> = new Case1 {
		inner: p1
	}
	p2.inner.case1(p1.a,p1.b)
	//case2  new struct
	p3<Case1> = new Case1 {
		inner: new Case1 {
			a: 22,
			b: 33,
		},
		c: new Case1 {
			a: 44,
			b: 55
		}
	}
	p3.inner.case1(22.(i8),33.(i8))
	//case3  structmember
	p4<Case1> = new Case1 {
		inner: p3.c
	}
	p4.inner.case1(
		p3.c.a,
		p3.c.b
	)
	//case4 func
	p5<Case1> = new Case1 {
		inner: newcase1(77.(i8),88.(i8))
	}
	p5.inner.case1(77.(i8),88.(i8))

	//case5 chain
	p6<Case1>  = new Case1 {
		inner: p3.c.get()
	}
	p6.inner.case1(44.(i8), 55.(i8))

	//case6 array field
	p7<Case1> = new Case1 {
		arr: [
			newcase1(111.(i32),222.(i32)),
			newcase1(333.(i32),444.(i32)),
			newcase1(555.(i32),66.(i32)),
		]
	}
	p7.arr[1].case1(333.(i32),444.(i32))
	//case7
	p8<ApiCase1> = new Case1 {a: 12,b: 34}
	p9<ApiCase1> = p8
	p9.case1(12.(i8),34.(i8))

	fmt.println("test struct inner api success")
}