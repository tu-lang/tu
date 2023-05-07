use fmt
use os

//类型转换以最左原则为准，左边是目标类型
//11887393157837578923 -6559350915871972693
//4294966295  -1001
//64535		  -1001
//155		  -101
func equal_not(){
	fmt.println("equal =  or  equal not != test")
	v1<u64> =  11887393157837578923
	v2<i64> =  -6559350915871972693
	if v1 == v2 {} else  os.die("v1 != v2")
	if v2 != v2 os.die("v1 != v2")
	v3<u32> = 4294966295
	v4<i32> = -1001
	if v3 == v4 {} else os.die("v3 != v4")
	if v4 != v3 os.die("v4 != v3")
	v5<u16> = 64535
	v6<i16> = -1001
	if v5 == v6 {} else os.die("v5 != v6")
	if v6 != v5 os.die("v6 != v5")
	
	fmt.println("test equal and not equal pass")
}
//> && >=
func great_than(){
	//u64 > i32
	v1<u64> = 11887393157837578923 //-6559350915871972693
	v2<i32> = 2147483647
	if v1 > v2 {} else {
		os.die("v1 > v2")
	}
	if v2 > v1 {} else {
		os.die("v2 > v1")
	}
	//i64 > i32
	v3<i64> = 11887393157837578923 //-6559350915871972693
	v4<i32> = 2147483647
	if v3 > v4 {
		os.die("v3 not > v4")
	}

	v5<i64> = -6559350915871972693
	v6<u64> = 11887393157837578923
	if v6 >= v5 {} else {
		os.die("v5 >= v6")
	}

	fmt.println("test > & >= success")
}
//< && <=
func less_than(){
	//u64 > i32
	v1<u64> = 11887393157837578923 //-6559350915871972693
	v2<i32> = 2147483647
	v3<i64> = 11887393157837578923
	if v1 < v2 {
		os.die("v1 < v2")
	}
	if v2 < v1 {
		os.die("v2 < v1")
	}
	if v3 < v2 {} else {
		os.die("v3 < v2")
	}
	v5<i64> = -6559350915871972693
	v6<u64> = 11887393157837578923
	if v6 <= v5 {} else {
		os.die("v6 <= v5")
	}
	if v5 <= v6 {} else {
		os.die("v5 <= v6")
	}

	fmt.println("test < & <= success")
}

// a || b
func log_or(){
	fmt.println("test log_or || condition expression")
	v1<u64> = 11887393157837578923 //-6559350915871972693
	v2<i32> = 2147483647	
	if v1 < v2 ||  v2 < v1  {
		os.die("log_or failed")
	}
	if v1 < v2 || v1 >= -6559350915871972693 {} else {
		os.die("log_or failed 2")
	}
	fmt.println("test log_or success")
}
// a && b
func log_and(){
	fmt.println("test log_and || condition expression")
	v1<u64> = 11887393157837578923 //-6559350915871972693
	v2<i32> = 2147483647	
	v3<u32> = 4294966295
	v4<i32> = -1001

	if v2 < v1 && v3 < v1 {
		os.die("should be here")
	}
	if v1 <= -6559350915871972693 && v4 == v3 {} else {
		os.die("should be here2")
	}
	fmt.println("test log_and success")

}
func main(){
	equal_not()
	great_than()
	less_than()
	log_or()
	log_and()
}