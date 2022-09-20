
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
func test_char2_logor(){
    fmt.println("test_char2_logor ")
    //test char || char  => bool
    if 'd' && 'D' {} else {
        os.panic("d && D => true")
    }
    //char || string     => bool
    if 'd' && "str" {} else {
        os.panic("d && str => true")
    }
    //char to int        => bool
    if 'd' && 0  {
        os.panic(" d || 0 => true")
    }
    if 0 && '0'  {
        os.panic("0 || '0' => true")
    }
    if 10 && '0'  {} else {
        os.panic("10 || '0' => true")
    }
    fmt.println("test_char2_logor success")
}
func main(){
    test_int()
    test_string()
    test_char2_logor()
}