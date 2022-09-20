
use fmt
use os

func test_int(){
    a = 10
    b = 10
    a = a / b
    if  a != 1 {
        fmt.printf("test int div %d != 1 failed\n",a)
        os.exit(1)
    }
    c = 10
    b = 2
    a = c / b
    if  a != 5 {
        fmt.printf("test int div %d != 5 failed\n",a)
        os.exit(1)
    }
    e = 50 / 2
    if  e != 25 {
        fmt.printf("test int div %d != 25 failed\n",e)
        os.exit(1)
    }
    fmt.printf("test int div %d  success\n",e)
}
// 对字符串做运算不做任何操作 都返回0
func test_string(){
    a = "abc"
    a = a / 1
    if  a != 0 {
        fmt.printf("test string div %d != 0 failed\n",a)
        os.exit(1)
    }
    a = 1 / "abc"
    if  a != 0 {
        fmt.printf("test string div %d != 0 failed\n",a)
        os.exit(1)
    }
    c = "abc" / "abc"
    if  c != 0 {
        fmt.printf("test string div %d != 0 failed\n",c)
        os.exit(1)
    }
    fmt.printf("test string div %d  success\n",a)
}

// test
func test_intp(str){
    if  str != 0 {
        fmt.printf("test string div %d != 0 failed\n",0)
        os.exit(1)
    }
    fmt.printf("test string div %d != 0 success\n",str)
}
func test_char2_div(){
    fmt.println("test_char2_div ")
    //test char & char  => int
    c1 = 'd' / 'D'
    v  = 100 / 68
    if c1 == v {} else {
        os.panic("c1:%d should be %d",c1,v)  
    }
    //char & string     => unsupport
    //char to int        => int
    c1 = 'd' / 68
    if c1 == v {} else {
        os.panic(" 'd' / 68 c1:%d should be %d",c1,v)
    }
    c1 = 68 / 'd'
    if c1 == 68 / 100 {} else {
        os.panic("68 / 100 c1:%d should be %d",c1,v)
    }
    fmt.println("test_char2_div success")
}
// 除法测试
func main(){
    test_int()
    test_string()
    test_intp("test" / 1)
    test_char2_div()
}