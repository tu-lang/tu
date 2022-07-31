
use fmt
use os

func test_array_index()
{
    a = [1,"2","3333","this is 4"]
    if  a[0] != 1 {
        fmt.println("a[0] == 1 failed")
        os.exit(1)
    }
    if  a[1] != "2" {
        fmt.println("a[1] == 2 failed")
        os.exit(1)
    }
    if  a[2] != "3333" {
        fmt.println("a[2] == 3333 failed")
        os.exit(1)
    }
    if  a[3] != "this is 4" {
        fmt.println("a[3] == this is 4 failed")
        os.exit(1)
    }
    fmt.print("array_get success",":",a)

}
func test_array_update()
{
    a = [1,2,3,5,6]
    if  a[0] != 1 {
        fmt.println("a[0] != 1 failed")
        os.exit(1)
    }
    a[0] = "sdfds"
    if  a[0] != "sdfds" {
        fmt.println("a[0] != sdfds failed")
        os.exit(1)
    }
    a[1] = 1000
    if  a[1] != 1000 {
        fmt.println("a[1] != 1000 failed")
        os.exit(1)
    }
    fmt.print("array_update success",":",a)
}

func test_array_add(){
    a   = []
    a[] = 1
    if  a[0] != 1 {
        fmt.println("a[0] != 0 failed")
        os.exit(1)
    }
    a[] = "sdfs"
    if  a[1] != "sdfs" {
        fmt.println("a[1] != sdfs failed")
        os.exit(1)
    }
    a[] = "---"
    if  a[2] != "---" {
        fmt.println("a[2] != --- failed")
        os.exit(1)
    }
    fmt.print("array_add success",":",a)
}
func test_array_merge(){
    fmt.println("test array_merge ")

	a = [1,"hello",4]
	b = [5,3]
	if !std.merge(a,b) 
        os.die("merge a,b failed")
    //test origin 
    fmt.assert(a[0] ,1)
    fmt.assert(a[1] ,"hello")
    fmt.assert(a[2] ,4)
    fmt.assert(a[3] ,5)
    fmt.assert(a[4] ,3)

    fmt.assert(b[0],5)
    fmt.assert(b[1],3)
    fmt.println("test array_merge success")
}

func main(){
    test_array_index()
    test_array_update()
    test_array_add()
    test_array_merge()
}
