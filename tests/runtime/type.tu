use fmt
use os
use temp
use runtime
//测试基础类型的typeid
func test_base(){
	fmt.println("test base...")
	a = 0 #int
	b = "string" # string
	c = {} # map
	d = [] # array

	if type(a) != type(int) os.die("a should be int")
	if type(b) != type(string) os.die("b should be string")
	if type(c) != type(map)   os.die("c should be map")
	if type(d) != type(array) os.die("d should be array")
	fmt.println("test base success..")
}
//测试class
class AA{}
class B{}
class C : B {}
func test_object(){
	fmt.println("test object")
	a = new AA()
	b = new B()
	c = new C()
	if type(a) != type(AA) os.die("a should be class AA")
	if type(b) != type(B) os.die("a should be class B")
	if type(c) != type(C) os.die("a should be class C")
	fmt.println("test object success")
}
func test_out_object(){
	fmt.println("test out object")
	a = new temp.Inner1()
	b = new temp.Inner2()
	if type(a) != type(temp.Inner1) os.die("a should be class temp.Inner1")
	if type(b) != type(temp.Inner2) os.die("a should be class temp.Inner2")
	fmt.println("test out object success",type(temp.Inner1),type(a),type(temp.Inner2),type(b))
}
class A{
	arr = [2,"test",[1,"test"]]
	func getarr(){return this.arr}
}
gvar = new A()
func test_complex_expr(){
	if type(gvar.arr) != type(array) os.dief("gvar.arr:%s should be array",runtime.type_string(gvar.arr))
	if type(gvar.arr[0]) != type(int) os.die("gvar.arr should be int")
	if type(gvar.arr[1]) != type(string) os.die("gvar.arr should be string")
	if type(gvar.arr[2][0]) != type(int) os.die("gvar.arr[2][0] should be int")
	if type(gvar.getarr()[2][1]) != type(string) os.die("should be string in chain express")
	cf = fn(){}
	if type(cf) != type(function) os.die("should be function")
	fmt.println("test complex expression sucess")
}
func main(){
	test_base()
	test_object()
	test_out_object()
	test_complex_expr()
}