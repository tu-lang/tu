use fmt

mem Test{
	i8 a,b,c,d,e,f,g,h
}
mem Pointer{
	i8* up
}
// i8测试
func i8_test(){
	p<Test> = new Test
	member = func(p<Test>){
		pp<Pointer> = new Pointer
		pp.up = &p.h
		for(i = 8 ; i >= 1 ; i -= 1 ){
			fmt.assert(int(*pp.up),i)
			pp.up -= 1
		}
		fmt.println("test i8 member pointer + success")
	}
	// 测试 变量指针 +
	var = func(p<Test>){
		p.a = 1 p.b = 2 p.c = 3 p.d = 4 p.e = 5 p.f = 6 p.g = 7 p.h = 8
		pp<i8*> = &p.h
		for(i = 8 ; i >= 1 ; i -= 1 ){
			fmt.assert(int(*pp),i)
			pp -= 1
		}
		fmt.println("test i8 var pointer + success")
	}
	var(p)
	member(p)
}

mem Testu8{
	u8 a,b,c,d,e,f,g,h
}
mem Pu8{
	u8* p
}
func u8_test(){
	p<Testu8> = new Testu8
	// 初始化值 u8 范围为 0 - 255
	pp<u8*> = &p.h
	for(i = 228 ; i > 220 ; i -= 1){ 
		*pp = *i 
		pp -= 1
	}
	member = func(p<Testu8>){
		pp<Pu8> = new Pu8
		pp.p = &p.h
		for(i = 228 ; i > 220 ; i -= 1 ){
			fmt.assert(int(*pp.p),i)
			pp.p = pp.p - 1
		}
		fmt.println("test u8 member pointer + success")
	}
	// 测试 变量指针 +
	var = func(p<Testu8>){
		pp<u8*> = &p.h
		for(i = 228 ; i > 220 ; i -= 1 ){
			fmt.assert(int(*pp),i)
			pp -= 1
		}
		fmt.println("test u8 var pointer + success")
	}
	var(p)
	member(p)
}
mem I8Mi64 {
	i8  a[2]
	i64 b[2]
}
func test_i8_sub_i64(){
	p<I8Mi64> = new I8Mi64 {
		b : [ 1,1]
	}
	i<i32> = 0
	b<i64> = 1
	if i - b < 0 {} else os.die("0 - 1 < 0 ;1")
	if i - 1 < 0 {} else os.die("0 - 2 < 0 ;2")
	if p.a[0] - p.b[0] < 0 {} else os.die("0-1 <0 3")
	if p.a[0] - 1 < 0 {} else os.die("0-1 <0 4")

	j<i16> = 0
	if j - b < 0 {} else os.die("0 - 1 < 0 ;3")
	if j - 1 < 0 {} else os.die("0 - 1 < 0 ;4")

	k<i8> = 0
	if k - b < 0 {} else os.die("0 - 1 < 0 ;5")
	if k - 1 < 0 {} else os.die("0 - 1 < 0 ;6")

	o<i64> = 0
	if o - b < 0 {} else os.die("0 - 1 < 0 ;7")
	if o - 1 < 0 {} else os.die("0 - 1 < 0 ;8")


	fmt.println("test i8 sub i64 success")
}
func test_u8_sub_u64(){
	i<u32> = 0
	b<u64> = 1
	if i - b < 0  os.die("0 - 1 < 0 ;1")
	// OPTIMIZE: i:u32   1:i64  => result: i64
	// if i - 1 < 0  os.die("0 - 2 < 0 ;2")

	j<u16> = 0
	if j - b < 0  os.die("0 - 1 < 0 ;3")
	// OPTIMIZE: i:u16   1:i64  => result: i64
	// if j - 1 < 0  os.die("0 - 1 < 0 ;4")

	k<u8> = 0
	if k - b < 0  os.die("0 - 1 < 0 ;5")
	// OPTIMIZE: i:u8   1:i64  => result: i64
	// if k - 1 < 0  os.die("0 - 1 < 0 ;6")

	o<u64> = 0
	if o - b < 0  os.die("0 - 1 < 0 ;7")
	// OPTIMIZE: i:u64   1:i64  => result: i64
	// if o - 1 < 0  os.die("0 - 1 < 0 ;8")
	fmt.println("test i8 sub i64 success")
}
func main(){
	i8_test()
	u8_test()
	test_i8_sub_i64()
	test_u8_sub_u64()
}