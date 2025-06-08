use os
use fmt
mem T2 {
	i8  a
	i32 b
	i64 c
}
T2::test(){
	if this.b  == 22 {} else os.die("this.b == 22")
	fmt.println("test t2 success")
}
mem T1 {
	i32 a
	i64 b[3]
	T2* c
	T2  d
}

gvar<T1:> = new T1 {
	a : 1,
	b : [31,32,33],
	c : 3,
	d : T2 {
		a : 11,
		b : 22,
		c : 33
	}
}
T1::test(){
	if this.a == 1 {} else os.die("this.a == 1")
	if this.b[0] == 31 {} else os.die("this.b[0] == 31")
	if this.b[1] == 32 {} else os.die("this.b[1] == 32")
	if this.b[2] == 33 {} else os.die("this.b[2] == 33")

	if this.d.a == 11 {} else os.die("this.d.a == 11")
	if this.d.b == 22 {} else os.die("this.d.a == 22")
	if this.d.c == 33 {} else os.die("this.d.a == 33")
	
	//test overflow
	this.b[3] = 35
	if this.c == 35 {} else os.die("this.c == 34")
	//test t2
	fmt.println("T1::test success")
	this.d.test()
}

mem Demo {
	i32 a
	f32 b
}
const Demo::new(a<i32>) Demo {
	return new Demo {
		a: a,
		b: 333.3
	}
}
const Demo::new2() {
	return "new2"
}