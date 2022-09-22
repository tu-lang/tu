
use os
use fmt
use std

func test_rand(){
    fmt.println("test_rand")

    v1 = std.rand(100)
    v2 = std.rand(100)
    if v1 > 100 os.die("v1 should < 100")
    if v2 > 100 os.die("v2 should < 100")
    if v1 == v2 os.die("v1 != v2")

    fmt.println("test_rand success")
}
func test_len(){
    fmt.println("test std.len")
    a = null
	if std.len(a) == 0 {} else os.die("len should be 1 and with warning")
	a = 100
	if std.len(a) == 1 {} else os.die("len should be 1 and with warning")
	a = true
	if std.len(a) == 1 {} else os.die("len should be 1 and with warning")
	a = "test"
	if std.len(a) == 4 {} else os.dief("len should be 4 %d",std.len(a))
	a = [1,2,4,"test"]
	if std.len(a) == 4 {} else os.dief("len should be 4")
	//unsupport map
    fmt.println("test std.len success")
}
func main(){
    test_rand()
    // fmt.println("before")
    //os.daemon()
    // fmt.println("after")
}