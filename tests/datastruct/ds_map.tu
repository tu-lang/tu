
use fmt
use os

func test_map_index()
{
    a = {1:1,"2":"2","3333":"3333","this is 4":"this is 4"}
    if  a[1] != 1 {
        fmt.println("a[1] == 1 failed")
        os.exit(1)
    }
    if  a["2"] != "2" {
        fmt.println("a[2] == 2 failed")
        os.exit(1)
    }
    if  a["3333"] != "3333" {
        fmt.println("a[2] == 3333 failed")
        os.exit(1)
    }
    if  a["this is 4"] != "this is 4" {
        fmt.println("a[3] == this is 4 failed")
        os.exit(1)
    }
    fmt.println("map_get success",a[1],a["2"],a["3333"],a["this is 4"])

}
func test_map_update()
{
    a = {}
    a[0] = "sdfds"
    if  a[0] != "sdfds" {
        fmt.println("a[0] != sdfds failed")
        os.exit(1)
    }
    a["this is 1000"] = 1000
    if  a["this is 1000"] != 1000 {
        fmt.println("a[this is 1000] != 1000 failed")
        os.exit(1)
    }
    fmt.print("map_update success",a[0],a[1],a[2],a[3],a[4])
}

func test_map_add(){
    a   = {}
    a[0] = 1
    if  a[0] != 1 {
        fmt.println("a[0] != 0 failed")
        os.exit(1)
    }
    a["---"] = "sdfs"
    if  a["---"] != "sdfs" {
        fmt.println("a[---] != sdfs failed")
        os.exit(1)
    }
    a["999"] = "---"
    if  a["999"] != "---" {
        fmt.println("a[999] != --- failed")
        os.exit(1)
    }
    fmt.print("map_add success",a[0],a["---"],a["999"])
}

func main(){
    test_map_index()
    test_map_update()
    test_map_add()
}
