use fmt
use os

use file
use file.file2

func testobj1(obj)
{
	fmt.println("test file.File")
	obj.init()
	obj.SetVar1("obj.var1")
	if  obj.var1 != "obj.var1" {
		fmt.println("obj.var1 != obj.var1 ",obj.var1)
		os.exit(-1)
	}
	fmt.println("test file.File passed")
}
func testobj2(obj)
{
	fmt.println("test file.fle2.File")
	obj.init()
	obj.SetVar1("obj2.var1")
	if  obj.var1 != "obj2.var1" {
		fmt.println("obj.var1 != obj2.var1")
		os.exit(-1)
	}
	fmt.println("test file.file2.File passed")
}


func main(){
	obj = new file.File()
	obj2 = new file2.File()
	testobj1(obj)
	testobj2(obj2)
}