
use fmt
use os
use pkg2

func array_test()
{
    fmt.println("global array test")
    pkg2.global_var = [1,"two","three"]
    if  pkg2.global_var[0] != 1 {
        fmt.print("pkg2.global_var[0] == 1 failed\n")
        os.exit(1)
    }
    if  pkg2.global_var[1] != "two" {
        fmt.print("pkg2.global_var[1] == two failed\n")
        os.exit(1)
    }
    pkg2.global_var[1] = "not two anymore"
    if  pkg2.global_var[1] != "not two anymore" {
        fmt.print("pkg2.global_var[1] == ... failed\n")
        os.exit(1)
    }
    pkg2.global_var[] = "four"
    if  pkg2.global_var[3] != "four" {
        fmt.print("pkg2.global_var[3] == four failed\n")
        os.exit(1)
    }
    fmt.print("global array test success\n")
}
func map_test()
{
    fmt.println("global map test\n")
    pkg2.global_var = {1:1,"two":"two","three":"three"}
    if  pkg2.global_var[1] != 1 {
        fmt.print("pkg2.global_var[1] == 1 failed\n")
        os.exit(1)
    }
    if  pkg2.global_var["two"] != "two" {
        fmt.print("pkg2.global_var[two] == two failed\n")
        os.exit(1)
    }
    pkg2.global_var["four"] = "four"
    if  pkg2.global_var["four"] != "four" {
        fmt.print("pkg2.global_var[four] == four failed\n")
        os.exit(1)
    }
    fmt.print("global map test success\n")
}

func main(){
    array_test()
    map_test()
}
