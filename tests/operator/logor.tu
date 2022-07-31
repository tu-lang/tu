
use fmt
use os

func test_int(){
    a = 0
    b = 0
    if  a && b {
        fmt.print("test int logor  0 && 0 failed",a)
        os.exit(1)
    }
    b = 1
    if  a && b {
        fmt.print("test int logor  0 && 1 failed",a)
        os.exit(1)
    }
    a = 1
    if  a && b {
        fmt.print("test int logor  1 && 1 success")
    }else{
        fmt.print("test int logor  1 && 1 failed")
        os.exit(1)
    }

    if  1 && 0 {
        fmt.print("test int logor  1 && 0 failed")
        os.exit(1)
    }
    fmt.print("test int logor  success")
}
func test_string(){
    a = ""
    b = ""
    if  a && b {
        fmt.print("test string logor  &&  failed")
        os.exit(1)
    }
    b = "o"
    if  a && b {
        fmt.print("test string logor  &&  failed")
        os.exit(1)
    }
    a = "0"
    if  a && b {
        fmt.print("test string logor  &&  succeed")
    }else{
        fmt.print("test string logor  &&  failed")
        os.exit(1)
    }

    if  "" && "" {
        fmt.print("test string logor  && failed")
        os.exit(1)
    }
    fmt.print("test string logor  success")
}

func main(){
    test_int()
    test_string()

}