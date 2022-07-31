
use os
use fmt

func string_test(){
    fmt.println("[gc] string_test")
    a = "test"
    fmt.println(a)
    os.gc()
    if  a != "test" {
        fmt.println("failed",a)
        os.exit(1)
    }
    fmt.println("[gc] string_test success")

}
func array_test(top){
    fmt.println("[gc] array_test")
    arr = []
    i   = 0
    while i < top {
        arr[] = i
        i += 1
    }
    os.gc()
    i  = 0
    while i < top {
        os.gc()
        if  arr[i] != i {
            fmt.println("[gc] arr[%d] != %d\n",arr[i],i)
            os.die("")
        }
        i += 1
    }
    fmt.println("[gc] array_test success")
}
func  print_pascal_triangle(level)
{
    list = [ 1 ]
    i = 1
    while i <= level {
        k = 0
        temp_arr = []

        while k < i {
            var = 0
            if k == 0 || k == i - 1 {
                var = 1
            }else{
                var = list[k] + list[k - 1]
            }
            temp_arr[] = var
            k += 1
        }
        fmt.println("i=" + i + "  " + temp_arr)
        //fmt.println(i)
        list = temp_arr
        i   += 1
    }
}
func main(){
	//FIXME: gc is unstable right now
    //string_test()
    //array_test(100)
    // TODO: linker found something wrong
    //print_pascal_triangle(10)
    fmt.println("rt_os_gc test passed!")
}