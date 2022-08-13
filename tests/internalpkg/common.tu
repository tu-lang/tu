
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
func main(){
    test_rand()
    // fmt.println("before")
    //os.daemon()
    // fmt.println("after")
}