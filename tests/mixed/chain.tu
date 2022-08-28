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
func main(){
	test_chain()
}