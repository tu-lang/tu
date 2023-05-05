use fmt

mem Test {
	i32 a,b,c
}
Test::funcall(){
	v = this
	if v == 1 {} else os.die("funcall should be 1")
}
//FunCallExpr 
func test_funcall(){
	obj = 1
	obj.(Test).funcall()
	fmt.println("test funcall success")
}
//IndexExpr
mem Arr {
	i32 arr[3]
}
func test_index(){
	obj = new Arr{
		arr: [ 3,5,7]
	}
	ret<i32> = obj.(Arr).arr[0]
	if ret == 3 {} else os.die("obj.arr[0] != 3")

	if obj.(Arr).arr[1] == 5 {} else os.die("obj.arr[1] != 5") 

    obj.(Arr).arr[2] = 77
    if obj.(Arr).arr[2] == 77 {} else os.die("obj.arr[2] != 77")
	fmt.println("test index success")
}
//MemberExpr
mem Member {
	i8 a
	i32 b
}
func test_member(){
	obj = new Member {
		a : 33,
		b : 55
	}
	ret<i32> = obj.(Member).a
	if ret == 33 {} else os.die("obj.a != 33")
	if obj.(Member).a == 33 {} else os.die("obj.a != 33 .") 
	if obj.(Member).b == 55 {} else os.die("obj.b != 55 .") 

	obj.(Member).b = 100
    if obj.(Member).b == 100 {} else os.die("obj.Member.b != 100")
	fmt.println("test member success")
}
//StructMemberExpr
mem StructM {
	i8 a,b,c
}
mem StructC {
	i64 a,b,c 
}
func test_struct_member(){
	obj<StructM> = new StructM { a : 11 , b : 22 , c : 33}
	ret<i32> = obj.(StructC).a
	if ret == 11 os.die("obj.a == 11")

	if obj.(StructC).b == 22 os.die("obj.b == 22")
	if obj.(StructC).c == 33 os.die("obj.c == 33")
	
	obj.(StructC).c = 44
	if obj.(StructC).c == 44 {} else os.die("obj.c != 44")
	fmt.println("test sturct member success")
}
mem I{
	i8 a,b,c
}
I::test(){
	return this.a
}
class Test1{
	a = []
	inner
	func init(){
		this.inner = new I{a : 12,b : 13 , c : 14}
	}
}
func test_member_call(){
	obj =  new Test1()
	ret<i8> = obj.inner.(I).test()
	if ret == 12 {} else os.die("obj.inner.test != 12")
	fmt.println("test member call success")
}
func main(){
	test_funcall()
	test_index()
	test_member()
	test_struct_member()
	test_member_call()	
}