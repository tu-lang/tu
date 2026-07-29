use fmt
use os
use runtime

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

// Struct literal field: dyn.(u64) must match bits<u64> = dyn.(u64) for Cast in init.
mem LitBox {
	i32 tag
}
mem LitHold {
	u64 bits
}
func test_struct_init_typeassert(){
	b1 = new LitBox { tag: 7 }
	bits2<u64> = b1.(u64)
	h1<LitHold> = new LitHold { bits: b1.(u64) }
	bits3<u64> = h1.bits
	if bits3 != bits2 os.die("struct init typeassert bits mismatch")
	fmt.println("test struct init typeassert success")
}

// u64→mem cast + field write in api impl and package fn, under GC noise.
api TaSch {
	fn bump()
}
mem TaHolder {
	i32 pad
}
mem TaCore {
	i32 flag
}
TA_CORE_BITS<u64> = 0
fn ta_pkg_bump() {
	b<u64> = TA_CORE_BITS
	c<TaCore> = b.(TaCore)
	c.flag = c.flag + 1
}
impl TaSch for TaHolder {
	fn bump() {
		b<u64> = TA_CORE_BITS
		c<TaCore> = b.(TaCore)
		c.flag = c.flag + 1
	}
}
func test_u64_mem_cast_api_impl(){
	c<TaCore> = new TaCore
	c.flag = 0
	TA_CORE_BITS = c.(u64)
	ta_pkg_bump()
	h<TaHolder> = new TaHolder
	h.pad = 0
	s<TaSch> = h
	s.bump()
	if c.flag != 2 os.die("u64 mem cast before GC")
	i<i32> = 0
	while i < 50 {
		p<u64*> = runtime.malloc(32.(u64), 0.(i8), 1.(i8))
		p[0] = i.(u64)
		i = i + 1
	}
	runtime.GC()
	TA_CORE_BITS = c.(u64)
	ta_pkg_bump()
	s.bump()
	if c.flag != 4 os.die("u64 mem cast after GC")
	fmt.println("test u64 mem cast api impl success")
}
func main(){
	test_funcall()
	test_index()
	test_member()
	test_struct_member()
	test_member_call()
	test_struct_init_typeassert()
	test_u64_mem_cast_api_impl()
}