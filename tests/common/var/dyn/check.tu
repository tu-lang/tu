use runtime
use var
use std
use os
use fmt

funcvar = gen()
func gen(){
	return "gen"
}

func init(){
	if nothing != null os.die("uninitialized global var should be null")
	if str != "str2" os.die("str != str2")
	if int != 12345 os.die("int != 12345")
	if std.len(arr1) != 0 os.die("native.arr1 should be 0")
	if std.len(arr2) != 3 os.die("native.arr2 should be 3")
	if arr2[1] != "test" os.die("native.arr2[1] should be test")
	if map2["len"] != 5 os.die("native.map2[test] should be 5")
	if funcvar != "gen" os.die("funcvar != gen")

	var.allcheck += 1
	fmt.println("var.dyn.test passed")
}