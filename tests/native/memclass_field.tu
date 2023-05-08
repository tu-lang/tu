use fmt
use string
use os

mem B {
	i8 a,b,c
}
B::test(){
	return this.a
}
mem A {
	B  inner
	B* inner2
}
A::test(){
	//test inner1
	if this.inner.b == 22 {} else os.die("this.inner.b != 22")
	ret<i8> = 11
	if this.inner.test() == ret {} else os.die("this.inner.a != 11")
	//test inner2
	if this.inner2.b == 55 {} else os.die("this.inner2.b != 55")
	ret = 44
	if this.inner2.test() == ret {} else os.die("this.inner.2 != 44")

	fmt.println("chain static member test success")
}
mem T
{
    i32 b
    i32 b2
    i32 n
    i32 c 
}
T::test_memfield_assign(){
    if this.b == true {} else {
        os.die("shoule be true")
    }
    if this.b2 == false {} else {
        os.die("should be false")
    }
    if this.n == null {} else {
        os.die("should be null")
    }
    if this.c == 'c' {} else {
        os.die("should be c")
    }
    fmt.println("test mem field base type assign success")
}
func main(){
	obj<A> = new A{
		inner: B{
			a : 11,
			b : 22,
			c : 33,
		}
		inner2 : new B{
			a : 44,
			b : 55,
			c : 66,
		}
	} 
	obj.test()
	//test2
    v<T> = new T {
        b : true,
        b2 : false,
        c : 'c',
        n : null
    }
	v.test_memfield_assign()
}