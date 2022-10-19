use runtime
use var
use std
use os
use fmt

str<i8*>      = "str2"     
int<i32>      = 12345
arr1<runtime.Value>      = []
arr2<runtime.Value>      = [1,"test",3]
arr3<std.Array>      = arr2.data

map1<runtime.Value> 	 = {}
map2<runtime.Value>      = {"arr":"arr","map":"map","len":5}

True<i8> = 1
False<i8> = 0
func init(){
	//strcmp return 0 if eq
	if std.strcmp(str,*"str2") != False {
		os.die("native.str != str2")	
	}
	if int != 12345 os.die("native.int != 12345")
	if std.len(arr1) != 0 os.die("native.arr1 should be 0")
	if std.len(arr2) != 3 os.die("native.arr2 should be 3")
	if arr3.used != 3 os.die("native.arr2.len should be 3")
	_arr2 = arr2
	_map2 = map2
	if _arr2[1] != "test" os.die("native.arr2[1] should be test")
	if _map2["len"] != 5 os.die("native.map2[test] should be 5")

	//finish checkd
	var.allcheck += 1
	fmt.println("var.native.test passed")
}