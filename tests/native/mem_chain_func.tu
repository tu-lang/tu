use fmt


mem Test{
	i64 a,b
	Inner plain
	Inner* pointer
}
mem Inner {
	i32 a,b
	i8  c,d
	i64 e
}
Inner::pointer(){
	if this.a != 100 os.die("this.a != 100")
	if this.d != 20 os.die("this.d != 20")
	return this.e
}
Inner::plain(){
	if this.a != 100 os.die("this.a != 100")
	if this.d != 20 os.die("this.d != 20")
	return this.e
}
func test_plan_member(var<Test>){
	var.plain.a = 100
	var.plain.d = 20
	var.plain.e = 300
	ret<i64> = var.plain.plain()
	if ret != 300 os.die("plain ret != 300")
	fmt.println("test plan member sucess")
}
func test_pointer_member(var<Test>){
	var.pointer = new Inner
	var.pointer.a = 100
	var.pointer.d = 20
	var.pointer.e = 400
	ret<i64> = var.pointer.pointer()
	if ret != 400 os.die("pointer ret != 300")
	fmt.println("test pointer member sucess")
}
func main(){
	var<Test> = new Test{}
	test_pointer_member(var)
	test_plan_member(var)
}