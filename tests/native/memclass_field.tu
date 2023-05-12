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
class Empty{}
gd = new Empty()
mem S1 {
	u64 a,b
}
//test dyn = static.member
func test_dyn_assign_static_member(){
	v<S1> = new S1 {
		a : 3425,
		b : 4321
	}
	gd.v1 = v.a
	if gd.v1 == v.a {} else {
		os.die("gd.v1 != v.a")
	}
	gd2 = new Empty()
	gd2.v2 = v.b
	if gd2.v2 == v.b {} else {
		os.die("gd2.v2 != v.b")
	}
	a<u64> = 3425
	if gd2.v2 == a {} else {
		os.die("gd2.v2 != 3425")
	}
	fmt.println("test_dyn_assign_static_member success")
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
	//test3
	test_dyn_assign_static_member
}