use fmt
use os


func test_8(){
	//4 bytes
	stack<i8:4> = 0
	//overflow
	overflow<i8> = 57
	p<i8*> = &stack
	//mem op
	p1<i8*> = p
	*p1 = 1 p1 += 1
	*p1 = 2 p1 += 1
	*p1 = 3 p1 += 1
	*p1 = 4
	if overflow != 57 os.die("oveflow != 1111")
	p2<i8*> = p
	if *p2 != 1 os.die("* p[0] != 1") p2 += 1
	if *p2 != 2 os.die("* p[1] != 2") p2 += 1
	if *p2 != 3 os.die("* p[2] != 3") p2 += 1
	if *p2 != 4 os.die("* p[3] != 4") 
	//test arr
	if p[0] != 1 os.die("p[0] != 1") 
	if p[1] != 2 os.die("p[1] != 2") 
	if p[2] != 3 os.die("p[2] != 3") 
	if p[3] != 4 os.die("p[3] != 4") 

	//test overflow
	p3<i8*> = p + 4
	*p3 = 5
	if *p3 != 5 os.die("p3 != 5")
	if p[4] != 5 os.die("p[4] != 5")
	//not overflow,cos 8 bytes align;maybe p[9] could coss overflow
	if overflow != 57 os.die("overflow != 5")

	fmt.println("test 8 success")
}
func test_16(){
	//8 bytes
	stack<i16:4> = 0
	//overflow
	overflow<i16> = 1616
	p<i16*> = &stack
	//mem op
	p1<i16*> = p
	*p1 = 1 p1 += 2 // add 2 bytes
	*p1 = 2 p1 += 2 
	*p1 = 3 p1 += 2
	*p1 = 4
	if overflow != 1616 os.die("oveflow != 1616")
	p2<i16*> = p
	if *p2 != 1 os.die("* p[0] != 1") p2 += 2
	if *p2 != 2 os.die("* p[1] != 2") p2 += 2
	if *p2 != 3 os.die("* p[2] != 3") p2 += 2
	if *p2 != 4 os.die("* p[3] != 4") 
	//test arr
	if p[0] != 1 os.die("p[0] != 1") 
	if p[1] != 2 os.die("p[1] != 2") 
	if p[2] != 3 os.die("p[2] != 3") 
	if p[3] != 4 os.die("p[3] != 4") 

	//test overflow
	p3<i16*> = p + 8
	*p3 = 5
	if *p3 != 5 os.die("p3 != 5")
	if p[4] != 5 os.die("p[4] != 5")
	//p[4] > 8bytes
	if overflow != 5 os.die("overflow != 5")

	fmt.println("test 16 success")
}
func test_32(){
	//16 bytes
	stack<i32:4> = 0
	//overflow
	overflow<i32> = 323232
	p<i32*> = &stack
	//开始内存操作
	p1<i32*> = p
	*p1 = 1 p1 += 4
	*p1 = 2 p1 += 4
	*p1 = 3 p1 += 4
	*p1 = 4
	if overflow != 323232 os.die("oveflow != 323232")
	p2<i32*> = p
	if *p2 != 1 os.die("* p[0] != 1") p2 += 4
	if *p2 != 2 os.die("* p[1] != 2") p2 += 4
	if *p2 != 3 os.die("* p[2] != 3") p2 += 4
	if *p2 != 4 os.die("* p[3] != 4") 
	//test arr
	if p[0] != 1 os.die("p[0] != 1") 
	if p[1] != 2 os.die("p[1] != 2") 
	if p[2] != 3 os.die("p[2] != 3") 
	if p[3] != 4 os.die("p[3] != 4") 

	//test overflow
	p3<i32*> = p + 16
	*p3 = 5
	if *p3 != 5 os.die("p3 != 5")
	if p[4] != 5 os.die("p[4] != 5")
	if overflow != 5 os.die("overflow != 5")

	fmt.println("test 32 success")
}
func test_64(){
	//32 bytes
	stack<i64:4> = 0
	//overflow
	overflow<i64> = 64646464
	p<i64*> = &stack
	//mem op
	p1<i64*> = p
	*p1 = 1 p1 += 8
	*p1 = 2 p1 += 8
	*p1 = 3 p1 += 8
	*p1 = 4
	if overflow != 64646464 os.die("oveflow != 64646464")
	p2<i64*> = p
	if *p2 != 1 os.die("* p[0] != 1") p2 += 8
	if *p2 != 2 os.die("* p[1] != 2") p2 += 8
	if *p2 != 3 os.die("* p[2] != 3") p2 += 8
	if *p2 != 4 os.die("* p[3] != 4") 
	//test arr
	if p[0] != 1 os.die("p[0] != 1") 
	if p[1] != 2 os.die("p[1] != 2") 
	if p[2] != 3 os.die("p[2] != 3") 
	if p[3] != 4 os.die("p[3] != 4") 

	//test overflow
	p3<i64*> = p + 32
	*p3 = 5
	if *p3 != 5 os.die("p3 != 5")
	if p[4] != 5 os.die("p[4] != 5")
	if overflow != 5 os.die("overflow != 5")

	fmt.println("test 64 success")
}

mem Test{
	i64* a,b,c
}
func test_mem_field(){
	var<Test> = new Test
	//arr[2]
	var.b = new 16
	p<i64*> = var.b
	//var.b[0]
	*var.b = 3333
	if *var.b != 3333 os.die("*var.b != 3333")
	if *p     != 3333 os.die("*p != 3333")
	//var.b[1]
	var.b += 8
	*var.b = 4444
	if *var.b != 4444 os.die("*var.b != 4444")
	if *p != 3333 os.die(" var.b *p != 3333")
	p += 8
	if *p != 4444 os.die("*var.b != 4444")
	//test arr op
	var.b = new 16
	p = var.b
	var.b[0] = 5555
	var.b[1] = 6666
	if var.b[0] != 5555 os.die("var.b[0] != 5555")
	if var.b[1] != 6666 os.die("var.b[0] != 6666")
	if *p != 5555 os.die("*p != 5555")
	p += 8
	if *p != 6666 os.die("*p != 6666")

	fmt.println("test_mem_field success")
}
mem Inner{
	i16* a,b,c
}
mem Chain{
	i64 a,b,c
	Inner* i1
	Inner i2
}
func test_chain_field(){
	var<Chain> = new Chain
	var.i1 = new Inner

	//arr[2]
	var.i1.a = new 4
	p<i16*> = var.i1.a
	*var.i1.a = 16
	if *var.i1.a != 16 os.die("*var.i1.a != 16")
	if *p     != 16 os.die("*p != 16")
	var.i1.a += 2
	*var.i1.a = 1616
	if *var.i1.a != 1616 os.die("*var.i1.a != 1616")
	if *p != 16 os.die("*p != 16")
	p += 2
	if *p != 1616 os.die("*p != 1616")
	//test arr op
	var.i1.a = new 4
	p = var.i1.a
	var.i1.a[0] = 16
	var.i1.a[1] = 1616
	if var.i1.a[0] != 16 os.die("var.b[0] != 16")
	if var.i1.a[1] != 1616 os.die("var.b[0] != 1616")
	if *p != 16 os.die("*p != 16")
	p += 2
	if *p != 1616 os.die("*p != 1616")

	fmt.println("test chain field success")
}
func test_var_index(){
	p<i8*> = new 4
	p[0] = 'a'
	if p[0] != 'a' os.die("p[0] != a")
	a<i8> = 2
	if p[a - 2] != 'a' os.die("p[0] != a")
	fmt.println("test_var_index success")
}

mem T1 {
    u8* p1
    u32 m1
    u32 m2
    u8* p2
}
fn test_complex_op(){
	fmt.println("test complex pointer op")

	b<u32> = 3
	onebit<u8> = 1
	v3<i64>		    = 16
	v4<i64>			= 1
	v5<u32>		= 1
	
	hb<u32> = (b & 3) | v3

	h<T1:> = null
	h.p1 = &onebit
	h.m1 = 4

	*h.p1 = *h.p1 &~ (v4 | v3 | ((v4 | v3) << v5)) << h.m1
	*h.p1 |= hb << h.m1

	if onebit == 48 {} else {
		os.die("one bit != 48")
	}
	fmt.println("test complex pointer op success")
}

func main(){
	test_8()
	test_16()
	test_32()
	test_64()

	test_mem_field()
	test_chain_field()

	test_var_index()

	test_complex_op()
}