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
		pp.up = p
		for(i = 1 ; i <= 8 ; i += 1 ){
			fmt.assert(int(*pp.up),i)
			pp.up += 1
		}
		fmt.println("test member pointer + success")
	}
	// 测试 变量指针 +
	var = func(p<Test>){
		p.a = 1 p.b = 2 p.c = 3 p.d = 4 p.e = 5 p.f = 6 p.g = 7 p.h = 8
		pp<i8*> = p
		for(i = 1 ; i <= 8 ; i += 1 ){
			fmt.assert(int(*pp),i)
			pp += 1
		}
		fmt.println("test var pointer + success")
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
	pp<u8*> = p
	for(i = 220 ; i <= 228 ; i += 1){ 
		*pp = *i 
		pp += 1
	}
	//FIXME: segfault
	member = func(p<Testu8>){
		fmt.println("test member pointer")
		pp<Pu8> = new Pu8
		pp.p = p
		for(i = 220 ; i <= 228 ; i += 1 ){
			fmt.assert(int(*pp.p),i)
			pp.p = pp.p + 1
		}
		fmt.println("test member pointer + success")
	}
	// 测试 变量指针 +
	var = func(p<Testu8>){
		pp<u8*> = p
		for(i = 220 ; i < 228 ; i += 1 ){
			//FIXME: gc bug
			//b = int(*i)
			fmt.assert(int(*pp),i)
			pp += 1
		}
		fmt.println("test var pointer + success")
	}
	var(p)
	member(p)
}
func main(){
	i8_test()
	//u8_test()
}