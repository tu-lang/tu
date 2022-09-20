
use fmt
use os

// 测试两个int 类型数据的比较
func test_int_greaterthan()
{
    fmt.println("test int greaterthan...\n")

    if   10 > 20 {
        fmt.println("test 10 > 20 failed...\n")
        os.exit(1)
    }else{
        fmt.println("test 10 > 20 success...\n")
    }
    a = 30
    b = 20
    if   a > b {
        fmt.printf("test %d > %d sucess...\n",a,b)
    }else{
        fmt.printf("test %d > %d failed...\n",a,b)
        os.exit(1)
    }
    if   10 > 10 {
        fmt.println("test 10 > 10 failed...\n")
        os.exit(1)
    }
    fmt.println("test int greater than success...\n")
}
// 测试字符串和字符串的比较
// 测试字符串和数字的比较
func test_string_greaterthan(){
    fmt.println("test string greaterthan...\n")

    a = "abc"
    b = "ab"
    if  a > b {
        fmt.printf("test %s > %s success...\n",a,b)
    }else{
        fmt.printf("test %s > %s failed...\n",b,a)
        os.exit(1)
    }
    b = "ac"
    if  b > a {
        fmt.printf("test %s > %s success...\n",b,a)
    }else{
        fmt.printf("test %s > %s failed...\n",b,a)
        os.exit(1)
    }

    a = "abc"
    b = 10
    c = a > b
    if  c == 0 {
        fmt.println("test abc > 10 success...\n")
    }else{
        fmt.println("test abc > 10 failed...\n")
        os.exit(1)
    }

    c = b > a
    if  c == 0 {
        fmt.println("test 10 > abc success...\n")
    }else{
        fmt.println("test 10 > abc failed...\n")
        os.exit(1)
    }

}
func test_char2_greater_equal(){
    fmt.println("test_char2_greater than")
    c1 = 'a' # 97
    c2 = 'z' # 122
    c3 = '0' # 48
    c4 = '9' # 57
    c5 = 'A' # 65
    c6 = 'Z' # 90
    //test char & char  => int
    if 'a' > c1          os.die("a not > a")
    if 'y' > c2          os.die("y should < z")
    if '0' > c3          os.die("0 not > 0")
    if '8' > c4          os.die("8 should < 9")
    if 'c' > c1 {} else  os.die("c > a")
    if '7' > c3 {} else  os.die("7 > 0")
    //char & string     => unsupport
    //char to int        => int
    if c5 > 65           os.die("65 not > 65")
    if 64 > c5           os.die("64 should < 65")
    if 80 > c5 {} else   os.die("85 should >= A")
    fmt.println("test_char2_greater equal  success")
}
// 测试大于
func main(){
    test_int_greaterthan()
    test_string_greaterthan()
    test_char2_greater_equal()
}

