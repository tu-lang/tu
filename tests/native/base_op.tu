use fmt

gvar<T1:1>
mem T1 {
	i8 a,b,d
	i8 c[3]
}
p<T1> = &gvar
//1. test reference global stack
//2. test global var stack
func test_ref_global_var(){
	//test reference global stack var gvar
	p2<T1> = &gvar
	p2.d = 11
	p2.c[0] = 22
	p2.c[1] = 33
	p2.c[2] = 44

	if p2.d == 11 {} else os.die("p2.d != 11")
	if p2.c[0] == 22 {} else os.die("p2.c[0] != 22")
	if p2.c[1] == 33 {} else os.die("p2.c[0] != 33")
	if p2.c[2] == 44 {} else os.die("p2.c[0] != 44")
	//test global p
	if p.d == 11 {} else os.die("p.d != 11")
	if p.c[0] == 22 {} else os.die("p.c[0] != 22")
	if p.c[1] == 33 {} else os.die("p.c[0] != 33")
	if p.c[2] == 44 {} else os.die("p.c[0] != 44")

	fmt.println("test ref global var&& global stack var success")
}
func test_i8_i32_mixed(){
	a<i8> = -5
	if a < 0 {} else os.die("-5 < 0")
	b<i32> = 5
	c<u8> = 14
	r<i32> = a + ( b % c)
	if r == 0 {} else os.die(" -5 + ( 5 % 15)  != 0")
	fmt.println("test_i_i32_mixed success")
}

func main(){
	test_ref_global_var()
	test_i8_i32_mixed()
}