use std
use string

fn case1_1(c) u8,i32,f64,f32,i8*,u64 {
	if c == "case1" {} else os.die("case1")
	return 257,111,123.456,789.111,"test", [
		11,22,33
	]
}
fn test_1_base_type(){
	fmt.println("test_1_base_type")

	v1<u8>,v2<i32>,v3<f64>,v4<f32>,v5<i8*>,arr = case1_1("case1")
	if v1 == 1 {} else os.die("neq 1")
	if v2 == 111 {} else os.die("neq 111")
	if v3 >= 123.4 && v3 <= 123.5 {} else 
		os.die("neq 123")
	if v4 >= 789.1 && v4 <= 789.2 {} else 
		os.die("neq 789")
	
	if string.new(v5) == "test" {} else {
		os.die("neq test")
	}

	if arr[0] == 11 && arr[1] == 22 && arr[2] == 33 {} else {
		os.die("neq arr")
	}
	fmt.println("test_1_base_type success")
}

fn case2_1() {
	v<f32> = 123.456
	return v
}
fn case2_2() {
	v<f64> = 123.456
	return v
}
fn case2_3() f32 {
	return 123.456
}
fn case2_4() f64 {
	return 123.456
}
fn case2_5() f32 {
	v<f32> = 123.456
	return v
}
fn case2_6() f32 {
	v<f64> = 123.456
	return v
}
fn test_1_base_type_cast(){
	fmt.println("test 1 base type cast")

	//dyn cast lost
	v<f64> = case2_1()
	vstr<string.String> = string.f64tostring(v)
	if vstr.dyn() == "0" {} else 
		os.die("cast failed")
	v2<f32> = case2_2()

	vstr = string.f64tostring(v2)
	if vstr.dyn() == "0" {} else 
		os.die("cast failed")
	
	// explict cast correct
	v3<f64> = case2_3()
	if v3 >= 123.4 && v3 <= 123.5 {} else 
		os.die("v3 failed")
	v4<f32> = case2_3()
	if v4 >= 123.4 && v4 <= 123.5 {} else 
		os.die("v4 failed")

	v5<f64> = case2_4()
	if v5 >= 123.4 && v5 <= 123.5 {} else 
		os.die("v5 failed")
	v6<f32> = case2_4()
	if v6 >= 123.4 && v6 <= 123.5 {} else 
		os.die("v6 failed")
	
	v7<f64> = case2_5()
	if v7 >= 123.4 && v7 <= 123.5 {} else 
		os.die("v7 failed")
	v8<f32> = case2_6()
	if v8 >= 123.4 && v8 <= 123.5 {} else 
		os.die("v8 failed")	
	
	fmt.println("test 1 base type cast success")
}

fn case3_1() u8 {
	return 257
}
fn case3_2() {
	ret<u8> = 257
	return ret
}
fn case3_3() i8 {
	return 128
}
fn case3_4() {
	ret<i8> = 128
	return ret
}
fn test_3_base_type_cast() {
	fmt.println("test3 base type cast")

	v1<i8> = case3_1()
	v2<i8> = case3_2()
	v3<u8> = case3_1()
	v4<u8> = case3_2()
	if v1 == 1 {} else os.die("v1 neq 1")
	if v2 == 1 {} else os.die("v2 neq 1")
	if v3 == 1 {} else os.die("v3 neq 1")
	if v4 == 1 {} else os.die("v4 neq 1")
	if case3_1() == 1 {} else os.die("case3_1 neq 1")

	v5<i8> = case3_3()
	v6<i8> = case3_4()
	v7<u8> = case3_3()
	v8<u8> = case3_4()
	if v5 == -128 {} else os.die("v5 neq -128")
	if v6 == -128 {} else os.die("v6 neq -128")
	if v7 == 128 {} else os.die("v7 neq 128")
	if v8 == 128 {} else os.die("v8 neq 128")
	
	fmt.println("test3 base type cast success")
}

mem Case3 {
	i32 a
}
Case3::test() Case3 {
	return this
}

fn case3_type() (Case3)
fn case3_type_origin(){
	return new Case3 {
		a: 133
	}
}

fn test_fnpointer(){
	fmt.println("test fnpointer")

	fc<case3_type> = case3_type_origin.(u64)
	if fc().test().a == 133 {} else {
		os.die("neq 133")
	}
	fmt.println("test fnpointer success")
}


mem Case4{
	i32 a
}
Case4::case2_1() {
	v<f32> = 123.456
	return v
}
Case4::case2_2() {
	v<f64> = 123.456
	return v
}
Case4::case2_3() f32 {
	return 123.456
}
Case4::case2_4() f64 {
	return 123.456
}
Case4::case2_5() f32 {
	v<f32> = 123.456
	return v
}
Case4::case2_6() f32 {
	v<f64> = 123.456
	return v
}
fn case4() Case4 {
	return new Case4{
		a: 200
	}
}
fn test4_chain_returncall_cast(){
	fmt.println("test4 chain returncall cast")

	//dyn cast lost
	v<f64> = case4().case2_1()
	vstr<string.String> = string.f64tostring(v)
	if vstr.dyn() == "0" {} else 
		os.die("cast failed")
	v2<f32> = case4().case2_2()

	vstr = string.f64tostring(v2)
	if vstr.dyn() == "0" {} else 
		os.die("cast failed")
	
	// explict cast correct
	v3<f64> = case4().case2_3()
	if v3 >= 123.4 && v3 <= 123.5 {} else 
		os.die("v3 failed")
	v4<f32> = case4().case2_3()
	if v4 >= 123.4 && v4 <= 123.5 {} else 
		os.die("v4 failed")

	v5<f64> = case4().case2_4()
	if v5 >= 123.4 && v5 <= 123.5 {} else 
		os.die("v5 failed")
	v6<f32> = case4().case2_4()
	if v6 >= 123.4 && v6 <= 123.5 {} else 
		os.die("v6 failed")
	
	v7<f64> = case4().case2_5()
	if v7 >= 123.4 && v7 <= 123.5 {} else 
		os.die("v7 failed")
	v8<f32> = case4().case2_6()
	if v8 >= 123.4 && v8 <= 123.5 {} else 
		os.die("v8 failed")	
	
	fmt.println("test 4 base type cast success")
}


mem Case5{
	i32 a
}
Case5::case3_1() u8 {
	return 257
}
Case5::case3_2() {
	ret<u8> = 257
	return ret
}
Case5::case3_3() i8 {
	return 128
}
Case5::case3_4() {
	ret<i8> = 128
	return ret
}
fn case5() Case5 {
	return new Case5{
		a: 333
	}
}
fn test_5_base_type_cast() {
	fmt.println("test5 base type cast")

	v1<i8> = case5().case3_1()
	v2<i8> = case5().case3_2()
	v3<u8> = case5().case3_1()
	v4<u8> = case5().case3_2()
	if v1 == 1 {} else os.die("v1 neq 1")
	if v2 == 1 {} else os.die("v2 neq 1")
	if v3 == 1 {} else os.die("v3 neq 1")
	if v4 == 1 {} else os.die("v4 neq 1")
	if case5().case3_1() == 1 {} else os.die("case3_1 neq 1")

	v5<i8> = case5().case3_3()
	v6<i8> = case5().case3_4()
	v7<u8> = case5().case3_3()
	v8<u8> = case5().case3_4()
	if v5 == -128 {} else os.die("v5 neq -128")
	if v6 == -128 {} else os.die("v6 neq -128")
	if v7 == 128 {} else os.die("v7 neq 128")
	if v8 == 128 {} else os.die("v8 neq 128")

	fmt.println("test5 base type cast success")
}
// FAILED!
// class A {
	// fn test() i32 {}
// }
// fn test_2_multi_return()i32{
	// return 1,2 
// }
mem Case6 {
	i32 a
	Case6Inner* inner
}
mem Case6Inner {
	i32 a
	i8 arr[3]
}
Case6::testTrue() i32 {
	return true
}
Case6::testFalse() i32 {
	return false
}
fn case6_1() Case6 {
	return new Case6 {
		a: 333
	}
}
fn case6_2() Case6 {
	return new Case6 {
		inner: new Case6Inner{
			a: 444
		}
	}
}
fn case6_3() Case6 {
	return new Case6 {
		inner: new Case6Inner{
			arr: [ 11,22,33]
		}
	}
}


fn test_condtion(){
	fmt.println("test condition")
	//case1 return fn
	if case6_1().testTrue() == true {} else os.die("neq true")
	if case6_1().testFalse() == false {} else os.die("neq false")
	v1<i32> = case6_1().testTrue()
	if v1 == true {} else os.die("neq true")
	v1 = case6_1().testFalse()
	if v1 == false {} else os.die("neq false")
	//case2 retunrn member
	if case6_2().inner.a == 444 {} else os.die("neq 444")
	//case2 return arr
	if case6_3().inner.arr[0] == 11 {} else 
		os.die("neq 11")
	if case6_3().inner.arr[1] == 22 {} else 
		os.die("neq 22")
	if case6_3().inner.arr[2] == 33 {} else 
		os.die("neq 33")
	fmt.println("test condition success")

}
fn main(){
	test_1_base_type()
	test_1_base_type_cast()
	test_fnpointer()
	test_3_base_type_cast()
	test4_chain_returncall_cast()
	test_5_base_type_cast()
	test_condtion()
}
