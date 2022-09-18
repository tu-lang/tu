
use fmt

//!
func test_lognot(){
	a = true
	if !a {
		os.die("not true")
	}
	b = false
	if !b != true {
		os.die("should true")
	}
	fmt.println("test lognot ! success")
}
//~
func test_bitnot(){
	//1010 1010 == 170
	a = 170
	//0101 0101 == -171
	b = ~a
	//FIXME: 
	if b != -171 {
		os.die("b should be 85 actl:" + b)
	}
	fmt.println("test bitnot success")
}
class A{
	obj
	func dot(){
		return true
	}
	func dof(){
		return false
	}
	func test(){
		if !this.obj.dot() {
			os.panic("!his.obj.dot == false")
		}
		if !this.obj.dof() {} else {
			os.panic("!his.obj.dof == true")
		}
	}
}
func test_lognotchain(){
	obj = new A()
	obj.obj = new A()
	obj.test()
	fmt.println("test_lognotchain success")
}
func main(){
	test_lognot()
	test_bitnot()
	test_lognotchain()
}