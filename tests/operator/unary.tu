
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

    v = null
    if !v {} else os.die("!null")
    v = 0
    if !v {} else os.die("!0")
    v = 1
    if !v os.die("!1")

    v = true
    if !v os.die("!true")
    v = false
    if !v {} else os.die("!false")

    v = '0'
    if !v {} else os.die("! char 0")
    v = '1'
    if !v os.die("! char 1")

    v = 1.2
    if !v os.die("!1.2")
    v = 0.0
    if !v {} else os.die("!0.0")

    v = ""
    if !v {} else os.die("!emptry string")
    v = "test"
    if !v os.die("!test")

    v = []
    if !v {} else os.die("! emptry arr")
    v = [1]
    if !v os.die("! emptry arr")

    v  = new Emptyc()
    if !v os.die("! obj")
    v = fn(){}
    if !v os.die("! func")
    v = {}
    if !v os.die("! map")

	fmt.println("test lognot ! success")
}
class Emptyc{}
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