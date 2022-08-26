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
	// TODO: 
	// obj.next.var = 20
	obj.next.setvar(20)
	if obj.next.var != 20 os.die("obj.next.var != 20")
	obj.next.setvar(30)
	if obj.next.getvar() != 30 os.die("obj.next.getvar() != 30")

	//TODO: obj.next.arr[] = new A()
	arr = obj.next.arr
	arr[] = new A()
	obj.next.arr[0].setvar(500)
	if obj.next.arr[0].getvar() == 500 {} else {
		os.die("obj.next.arr[0].getvar() != 500")
	}
	if obj.next.arr[0].getthis().var == 500 {} else {
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
	fmt.println("test chain arr success")
}
func main(){
	test_chain_member()
	test_chain_arr()
}