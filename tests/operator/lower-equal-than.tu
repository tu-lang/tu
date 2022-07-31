
use fmt
use os

func test_int_lowereqthan(){
    fmt.println("test int lower-eq-than...\n")
    if   10 <= 20 {
        fmt.println("test 10 <= 20 sucess...\n")
    }else{
        fmt.println("test 10 <= 20 failed...\n")
        os.exit(1)
    }
    a = 10
    b = 20
    if   a <= b {
        fmt.println("test 10 <= 20 sucess...\n")
    }else{
        fmt.println("test 10 <= 20 failed...\n")
        os.exit(1)
    }
    if   10 <= 10 {
        fmt.println("test 10 <= 10 sucess...\n")
    }else{
        fmt.println("test 10 <= 10 failed...\n")
        os.exit(1)

    }
    fmt.println("test int lower equal than success...\n")
}

func test_string_lowereqthan(){
    fmt.println("test string lower equal than...\n")
    a = "abc"
    b = "ab"
    if  b <= a {
        fmt.println("test %s <= %s success...\n",b,a)
    }else{
        fmt.println("test %s <= %s failed...\n",b,a)
        os.exit(1)
    }
    b = "abc"
    if  a <= b {
        fmt.println("test %s <= %s success...\n",a,b)
    }else{
        fmt.println("test %s <= %s failed...\n",a,b)
        os.exit(1)
    }

    a = "abc"
    b = 10
    c = a <= b
    if  c == 0 {
        fmt.println("test abc <= 10 success...\n")
    }else{
        fmt.println("test abc <= 10 failed...\n")
        os.exit(1)
    }

    c = b <= a
    if  c == 0 {
        fmt.println("test 10 <= abc success...\n")
    }else{
        fmt.println("test 10 <= abc failed...\n")
        os.exit(1)
    }

}

func main(){
    test_int_lowereqthan()
    test_string_lowereqthan()
}

