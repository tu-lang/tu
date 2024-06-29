use fmt
use os

fn offsetof(ptr1<i64> , ptr2<i64>){
	return ptr2  - ptr1
}

mem T1 {
	i8 a
	i8 b
}
mem T1P: pack {
	i8 a
	i8 b
}
fn test1(){
	fmt.println("test 1")

	if sizeof(T1) == 8  {} else os.die("t1 != 8")
	p<T1> = new T1 {}
	of<i64> = offsetof(p,&p.b)
	if of != 1 os.die("t1.b != 1")

	//pack
	if sizeof(T1P) == 2  {} else os.die("t1p != 2")
	p1<T1P> = new T1P{}
	of = offsetof(p1,&p1.b)
	if of != 1 os.die("t1p.b != 1")
	fmt.println("test 1 success")
}
mem T2 {
	i8 a 
	i8* b
	i8 c
}
mem T2P:pack {
	i8 a 
	i8* b
	i8 c
}
fn test2(){
	fmt.println("test 2")

	if sizeof(T2) == 24 {} else os.die("t2 != 24")	
	p<T2> = new T2{}
	ofb<i64> = offsetof(p,&p.b)
	ofc<i64> = offsetof(p,&p.c)
	if ofb == 8 {} else os.die("ofb != 8")
	if ofc == 16{} else os.die("ofc != 16")

	if sizeof(T2P) == 10 {} else os.die("t2p != 10")
	p2<T2P> = new T2P{}
	ofb = offsetof(p2,&p2.b)
	ofc = offsetof(p2,&p2.c)
	if ofb == 1 {} else os.die("ofb != 1")
	if ofc == 9 {} else os.die("ofc != 9")
	fmt.println("test 2 success")
}

mem T3_1 {
	i8 a
	i8* b
	i8* c
}
mem T3 {
	i8 a 
	T3_1 b
	i8 c
}
fn test3(){
	fmt.println("test 3")
	if sizeof(T3) == 40 {} else os.die("t3 != 40")
	p<T3> = new T3{}

	ofbb<i64> = offsetof(p,&p.b.b)
	ofc<i64>  = offsetof(p,&p.c)
	if ofbb == 16 {} else os.die("t3.b.b != 16")
	if ofc == 32 {} else os.die("ofc != 32")
	if sizeof(T3P) == 12 {} else os.die("t3p != 12")
	p2<T3P> = new T3P{}
	ofbb = offsetof(p2,&p2.b.b)
	ofc  = offsetof(p2,&p2.c)
	if ofbb == 2 {} else os.die("t3p.b.b != 2")
	if ofc == 11 {} else os.die("t3p.ofc != 11")

	fmt.println("test 3 success")
}
mem T3_1P:pack {
	i8 a
	i8* b
	i8 c
}
mem T3P:pack {
	i8 a 
	T3_1P b
	i8 c
}

mem T4_1 {
	i8 a
	i8* b
	i8 c
}
mem T4P:pack {
	i8 a 
	T4_1 b
	i8 c
}

fn test4(){
	fmt.println("test 4")
	p<T4P> = new T4P{}
	if sizeof(T4P) == 26 {} else os.die("t4p != 26")
	offbb<i64> = offsetof(p,&p.b.b)
	offc<i64> = offsetof(p,&p.c)
	if offbb == 9 {} else os.die("offb != 9")
	if offc == 25 {} else os.die("offc != 25")

	fmt.println("test 4 success")
}
mem T5_1P:pack {
	i8 a
	i8* b
	i8 c
}
mem T5 {
	i8 a 
	T5_1P b
	i8 c
}

fn test5(){
	fmt.println("test 5")
	p<T5> = new T5{}
	offbb<i64> = offsetof(p,&p.b.b)
	offc<i64> = offsetof(p,&p.c)
	if sizeof(T5) == 16 {} else os.die("t5 != 26")
	if offbb == 2 {} else os.die("offb != 9")
	if offc == 11 {} else os.die("offc != 25")

	fmt.println("test 5 success")
}
fn main(){
	test1()
	test2()
	test3()
	test4()
	test5()
}