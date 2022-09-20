
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
        fmt.printf("test %s <= %s success...\n",b,a)
    }else{
        fmt.printf("test %s <= %s failed...\n",b,a)
        os.exit(1)
    }
    b = "abc"
    if  a <= b {
        fmt.printf("test %s <= %s success...\n",a,b)
    }else{
        fmt.printf("test %s <= %s failed...\n",a,b)
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
func test_char2_lower_equal_than(){
    fmt.println("test_char2_lower equal than")
    c1 = 'a' # 97
    c2 = 'z' # 122
    c3 = '0' # 48
    c4 = '9' # 57
    c5 = 'A' # 65
    c6 = 'Z' # 90
    //test char & char  => int
    if 'a' <= c1 {} else os.die("a should <= a")
    if 'y' <= 'x'        os.die("y should >= x")
    if '0' <= '0' {} else os.die("0 <= 0")
    if '8' <= '9' {} else os.die("8 should <= 9")
    //char & string     => unsupport
    //char to int        => int
    if 'A' <= 65 {} else  os.die("65 >= 65")
    if 66 <= 'A'          os.die("66 should > 65")
    if 80 <= 'a' {} else  os.die("85 should <= 97")
    fmt.println("test_char2_lower equal than success")
}
func main(){
    test_int_lowereqthan()
    test_string_lowereqthan()
    test_char2_lower_equal_than()
}

