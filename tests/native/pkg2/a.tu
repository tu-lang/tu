use fmt
use os


mem B {
	i64 a,b
}
B::init(){
	if this.a == 20 && this.b == 30 {} else {
		os.die("B::init something wrong here")
	}
}
mem A {
	i64 a 
	B b
	i64 c
}
A::init(){
	if this.a == 10 && this.c == 40 {} else {
		os.die("A::init somthing wrong")
	}
	this.b.init()
}

g<A:> = new A{
	a : 10,
	b : B {
		a : 20,
		b : 30
	},
	c : 40
}

