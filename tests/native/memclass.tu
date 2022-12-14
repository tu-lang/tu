use fmt
use os

mem Test {
	i32 a
	i32 b,c
	i8*   arr8
	i16*  arr16
	i32*  arr32
	i64*  arr64
	i32   stack[3]
}
Test::value(){
	return this.b
}
Test::test(com){
	if this.a != 10 os.die("this.a != 10")
	if this.b != 20 os.die("this.a != 20")
	ret<i32> = this.value()
	if ret != 20 os.die("this.b != 20")
	this.arr8[0] = 13
	this.arr8[1] = 14
	if this.arr8[0] != 13 os.die("this.arr8[0] != 13")
	if this.arr8[1] != 14 os.die("this.arr8[1] != 14")

	if this.stack[1] != 2 os.die("this.stack[1] != 2")
	fmt.printf("test mem class by '%s' success \n",com)
}
func main(){
	var<Test> = new Test {
		a : 10, 
		b : 20, 
		arr8: new i8[2], 
		stack: [1,2,3], 
	}
	var.test("test heap")
	//stack test
	var2<Test:> = null
	var2.a = 10
	var2.b = 20
	var2.arr8 = new i8[2]
	var2.stack[0] = 1
	var2.stack[1] = 2
	var2.stack[2] = 3
	var2.test("test stack")

}