use fmt
use os
enum {
	Normal
	Error
}
class A {
	next 
	type = false
	native 
}
func test_chain(){
	//init
	obj = new A()
	obj.next = new A()
	obj.next.native = Error
	//    dyn                 &&      native      => native
	if obj.next.type == false && obj.next.native == Error {} else {
		os.die("should be true")
	}
	obj.next.type = Error // test wheather coredump in next right expression
	//     native               ||     dyn(if load instruct at here will coredump)
	if obj.next.native == Error || obj.next.type == false {} else {
		os.die("never happen at here") //cos obj.next.type will coredump
	}
	fmt.println("dyn with native in chain test success")

}
// Static fn driving dynamic chain calls with multiple returns; the dynamic
// callee itself mixes native locals into its result.
class MPair {
	tag = 0
	func init(t){ this.tag = t }
	func who(){ return this.tag, this.tag * 2 }
	func nativeSum(){
		s<i32> = 3
		return this.tag + int(s), this.tag
	}
}
class MHolder {
	cur
	func init(){ this.cur = new MPair(4) }
}
mem MBox {
	i32 base
}
fn static_chain_caller(box<MBox>) i32 {
	h = new MHolder()
	a, b = h.cur.who()
	c, d = h.cur.nativeSum()
	// 4 + 8 + 7 + 4
	if a + b + c + d != 23 {
		os.dief("static caller chain sum: %d %d %d %d", a, b, c, d)
	}
	r<i32> = box.base
	return r + 1
}
func test_chain_multiret_mixed(){
	box<MBox> = new MBox{ base: 9 }
	n<i32> = static_chain_caller(box)
	if n != 10 os.die("static_chain_caller != 10")
	fmt.println("mixed chain multiret test success")
}
func main(){
	test_chain()
	test_chain_multiret_mixed()
}