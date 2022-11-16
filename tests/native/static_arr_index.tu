use fmt

use fmt

mem Member{
	u64 arr[2]
	u64 end
	u32 pos
}
Member::test_struct_member_index(){
	if this.arr[this.pos] != 567 os.die("this.arr[this.pos] != 567")
	if this.arr[this.pos + 1] != 8910 os.die("this.arr[this.pos + 1] != 8910")
	this.pos += 1
	if this.arr[this.pos] != 8910 os.die("this.arr[this.pos] != 567")
	if this.end != 8888 os.die("this.end != 8888")

	this.pos = 0
	arr<i8*> = new i8[2]
	//init arr
	arr[0] = 33
	arr[1] = 44
	if arr[this.pos] != 33 os.die("arr[this.pos] != 33")
	if arr[this.pos + 1] != 44 os.die("arr[this.pos + 1] != 44")
	this.pos += 1
	if arr[this.pos] != 44 os.die("arr[this.pos] != 44")

	fmt.println("Member::test struct memeber index success")
}
func test_struct_member_index(){

	var<Member> = new Member{
		arr : [567,8910],
		end : 8888,
		pos : 0,
	}
	if var.arr[var.pos] != 567 os.die("var.addr[var.pos] != 567")
	if var.arr[var.pos + 1] != 8910 os.die("var.addr[var.pos + 1] != 8910")
	var.pos += 1
	if var.arr[var.pos] != 8910 os.die("var.addr[var.pos] != 567")
	if var.end != 8888 os.die("var.end != 8888")

	var.pos = 0
	arr<i8*> = new i8[2]
	//init arr
	arr[0] = 33
	arr[1] = 44
	if arr[var.pos] != 33 os.die("arr[var.pos] != 33")
	if arr[var.pos + 1] != 44 os.die("arr[var.pos + 1] != 44")
	var.pos += 1
	if arr[var.pos] != 44 os.die("arr[var.pos] != 44")

	fmt.println("test struct memeber index success")
}
use t
two<i32> = 2
mem StackArrSizeTest {
	i32 arr1[two]
	i32 arr2[t.ten]
	i64 arr3[t.seven]
}
func test_member_arrisze(){

	if sizeof(StackArrSizeTest) != two*4 + t.ten*4 + t.seven*8 {
		os.dief("stack arr size is %d",int(sizeof(StackArrSizeTest)))
	}
	var<StackArrSizeTest> = new StackArrSizeTest {
		arr1 : [11,22],
		arr2 : [111,222,333,444,555,666,777,888,999,1000],
		arr3 : [1111,2222,3333,4444,5555,6666,7777]
	}
	if var.arr1[1] == 22 {} else os.die("var.arr[1] != 22")
	if var.arr2[1] == 222 {} else os.die("var.arr2[1] != 222")
	if var.arr2[9] == 1000 {} else os.die("var.arr2[9] != 1000")
	if var.arr3[1] == 2222 {} else os.die("var.arr3[1] != 2222")
	if var.arr3[6] == 7777 {} else os.die("var.arr3[6] != 7777")

	var.arr1[1] = 90  
	if var.arr1[1] == 90 {} else os.die("var.arr1[1] == 90")
	if var.arr2[0] == 111 {} else os.die("var.arr2[0] == 111")

	var.arr2[9] = 91
	if var.arr2[9] == 91 {} else os.die("var.arr2[9] == 91")

	var.arr1[2] = 93
	if var.arr2[0] == 93 {} else os.die("var.arr2[0] == 93")

	fmt.println("test member arrsize success")
}

func main(){
	test_struct_member_index()
	var<Member> = new Member{
		arr : [567,8910],
		end : 8888,
		pos : 0,
	}
	var.test_struct_member_index()
	test_member_arrisze()
}