use os
use std

fn main(){
	case1()
	case2()
	case3()
	case4()
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