mem Case1 {
	i32 a
	Case1Inner* inner
}
mem Case1Inner {
	Case1Inner2* arr[3]
}
mem Case1Inner2 {
	u8 a,b
	i8 c,d
}
Case1Inner2::test(str) Case1Inner2 {
	if str == "case1"  {
		if this.a == 255 {} else os.die("should be 255")
		if this.b == 0 && this.c == 0 && this.d == 0 {} else 
			os.die("should be 0")
		return this
	}
	if str == "case2" {
		if this.b == 1 {} else os.die("test: should be 1")
		if this.a == 200 && this.c == 0 && this.d == 0 {} else 
			os.die("should be 0")
		return this
	}
	if str == "case3"  {
		if this.c == 127 && this.d == -128  {} 
			else os.die("should be 127 -128")
		if this.a == 50 && this.b == 0 {} else 
			os.die("should be 0")
		return this
	}

	fmt.println(str)
	os.die("Case2Inner::test failed:")
	return this
}
Case1Inner2::test2(v<i32>){
	if this.a == v {} else os.die("test2")
}
fn case1(){
	fmt.println("case1")
	p<Case1> = new Case1{
		inner: new Case1Inner{
			arr: [
				new Case1Inner2{a: 255},
				new Case1Inner2{a: 200,b: 257},
				new Case1Inner2{a: 50,c: 127,d: 128}
			]
		}
	}

	ret<i32> = p.inner.arr[0].test("case1").a
	if ret == 255 {} else {
		os.die("ret should be 255")
	}
	ret = p.inner.arr[1].test("case2").b
	if ret == 1 {} else {
		os.die("ret should be 1")
	}
	ret = p.inner.arr[2].test("case3").c
	if ret == 127 {} else {
		os.die("ret should be 127")
	}
	ret = p.inner.arr[2].test("case3").d
	if ret == -128 {} else {
		os.die("ret should be -128")
	}

	p.inner.arr[0].test2(
		p.inner.arr[0].a
	)
	p.inner.arr[1].test2(
		p.inner.arr[1].a
	)
	p.inner.arr[2].a = 33
	p.inner.arr[2].test2(
		p.inner.arr[2].a
	)
	fmt.println("case1 success")
} 


g_case2<Case2:> = [
	{1,0},{2,0}
]

mem Case2 {
	i32 a
	Case2Inner* inner
}
Case2::test(case) Case2 {
	if case == "case1" {
		if this.a == 2 {} else 
			os.die("should be 1")

		if this.inner.arr[0].arr[0] == 1 {} else os.die("neq 1")
		if this.inner.arr[0].arr[1] == 2 {} else os.die("neq 2")
		if this.inner.arr[0].arr[2] == 3 {} else os.die("neq 3")
		if this.inner.arr[1].arr[0] == 4 {} else os.die("neq 4")
		if this.inner.arr[1].arr[1] == 5 {} else os.die("neq 5")
		if this.inner.arr[1].arr[2] == 6 {} else os.die("neq 6")
		if this.inner.arr[2].arr[0] == 7 {} else os.die("neq 7")
		if this.inner.arr[2].arr[1] == 8 {} else os.die("neq 8")
		if this.inner.arr[2].arr[2] == 9 {} else os.die("neq 9")
		if this.inner.arr2[1].arr[0] == 10 {} else os.die("neq 10")
		if this.inner.arr2[1].arr[1] == 11 {} else os.die("neq 11")
		if this.inner.arr2[1].arr[2] == 12 {} else os.die("neq 12")
		return this
	}
	os.die("invalid case2")
	return this
}
mem Case2Inner {
	i32 a
	Case2Inner2  arr2[3]
	Case2Inner2* arr[3]
}
mem Case2Inner2 {
	i32 arr[3]
}
Case2Inner2::test(i<i32>,v<i32>) i32 {
	if this.arr[i] == v 
		return true
	else 
		return false
}
fn case2(){
	fmt.println("case2")
	//init
	g_case2[1].inner = new Case2Inner {
		a: 10,
		arr: [
			new Case2Inner2 {
				arr: [1,2,3]
			},
			new Case2Inner2 {
				arr: [4,5,6]
			},
			new Case2Inner2 {
				arr: [7,8,9]
			}
		]
	}
	inner<Case2Inner> = g_case2[1].inner
	inner.arr2[1].arr[0] = 10
	inner.arr2[1].arr[1] = 11
	inner.arr2[1].arr[2] = 12
	//test
	ret<i32> = g_case2[1].test("case1").inner.arr[1].arr[1]
	if ret == 5 {} else os.die("should be 5")

	g_case2[1].inner.arr[1].arr[2] = 55
	if g_case2[1].inner.arr[1].arr[2] == 55 {} else 
		os.die("should be 55")

	if g_case2[1].inner.arr[1].test(
		2.(i8),g_case2[1].inner.arr[1].arr[2]
	) {} else os.die("case2 check failed")


	fmt.println("case2 success")
}

mem Case3 {
	i32 a
	Case3Inner* inner
}
Case3::test(str) Case3 {
	if str == "case3" {} else os.die("neq case3")
	if this.a == 44 {} else os.die("neq 44")
	return this
}
mem Case3Inner {
	Case3Inner2* arr[3]
}
mem Case3Inner2 {
	i32 a,b,c
}
Case3Inner2::test() i32 {
	if this.a == 11 {} else os.die("neq 11")
	if this.b == 22 {} else os.die("neq 22")
	if this.c == 33 {} else os.die("neq 33")
	return true
}
fn case3_1() Case3 {
	return new Case3 {
		a: 44,
		inner: new Case3Inner {
			arr: [
				new Case3Inner2{
					a: 11,
					b: 22,
					c: 33
				},
				null,
				null
			]
		}
	}	
}
fn case3(){
	fmt.println("case3")
	if case3_1().test("case3").inner.arr[0].test() {} else {
		os.die("should be true")
	}
	fmt.println("case3 success")
}


mem Case4 {
	i32 a
	Case4Inner* inner
}
Case4::test(i<i32>) Case4Inner {
	if i == this.a {} else os.die("neq i")
	return this.inner
}
mem Case4Inner {
	i32 a,b,c,d
}
Case4Inner::test(a<i32>) Case4Inner {
	if a == this.a {} else os.die("neq this.a")

	if this.b == 88 {} else os.die("neq 88")
	if this.c == 99 {} else os.die("neq 99")
	if this.d == 100 {} else os.die("neq 100")
	return this
}


fn case4(){
	fmt.println("case4")
	p<Case4> = new Case4 {
		a : 66,
		inner: new Case4Inner {
			a: 77,
			b: 88,
			c: 99,
			d: 100
		}
	}
	if p.test(p.a).test(p.inner.a).d == 100 {} else 
		os.die("neq 100")
	fmt.println("case4 success")
}

fn main(){
	case1()
	case2()
	case3()
	case4()
}