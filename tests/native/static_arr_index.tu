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

func main(){
	test_struct_member_index()
	var<Member> = new Member{
		arr : [567,8910],
		end : 8888,
		pos : 0,
	}
	var.test_struct_member_index()
}