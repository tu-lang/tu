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
			t<i8> = *i
			t = t * t
			fmt.assert(int(*pp.up),int(t))
			pp.up += 1
		}
		fmt.println("test member Pointer + success")
	}
	// 测试 变量指针 +
	var = func(p<Test>){
		p.a = 1 p.b = 4 p.c = 9 p.d = 16 p.e = 25 p.f = 36 p.g = 49 p.h = 64
		pp<i8*> = p
		for(i = 1 ; i <= 8 ; i += 1 ){
			t<i8> = *i
			t *= t
			fmt.assert(int(*pp),int(t))
			pp += 1
		}
		fmt.println("test var Pointer + success")
	}
	var(p)
	member(p)
}
func main(){
	i8_test()
}