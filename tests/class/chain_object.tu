use fmt
use os

class A {
	var = 10
	next
	arr = []
	func getvar(){
		return this.var
	}
	func setvar(var){
		this.var = var
	}
	func getthis(){return this}
}
func test_chain_member(){
	obj = new A()
	if obj.var != 10 os.die("obj.var != 10")
	if obj.getvar() != 10 os.die("obj.var != 10")

	obj.next = new A()
	obj.next.var = 20
	if obj.next.var != 20 os.die("obj.next.var != 20")
	obj.next.setvar(30)
	if obj.next.getvar() != 30 os.die("obj.next.getvar() != 30")

	obj.next.arr[] = 500 
	obj.next.arr[0] = 501
	if obj.next.arr[0] == 501 {} else {
		os.die("obj.next.arr[0] != 501")
	}
	obj.next.arr[] = new A()
	obj.next.arr[1].setvar(500)
	if obj.next.arr[1].getvar() == 500 {} else {
		os.die("obj.next.arr[1].getvar() != 500")
	}
	if obj.next.arr[1].getthis().var == 500 {} else {
		os.die("obj.next.arr[0].getthis().var != 500")
	}
	fmt.println("test chain member success")
}
func test_chain_arr(){
	arr = [[new A()]]
	arr[0][0].getthis().setvar("test")
	if arr[0][0].getthis().getvar() == "test" {} else {
		os.die("should be test")
	}
	arr[0][0] = 500
	if arr[0][0] == 500 {} else {
		os.die("arr[0][0] != 500")
	}
	fmt.println("test chain arr success")
}
class B {
	arr = [100,333]
	func getarr(i){
		return this.arr[i]
	}
}
func test_complex(){
	if (new B()).arr[0] != 100 {
		os.die("arr[0] should be 100")
	}
	if (new B()).getarr(1) != 333 {
		os.die("arr[1] should be 333")
	}
	fmt.println("test complex situation success")
}
func main(){
	test_chain_member()
	test_chain_arr()
	test_complex()
}