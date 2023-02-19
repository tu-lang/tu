
use fmt
use os

func test_int(){
    a = 10
    b = 10
    a /= b
    if  a != 1 {
        fmt.printf("test int div %d != 1 failed\n",a)
        os.exit(1)
    }
    a = 10
    a /= 2
    if  a != 5 {
        fmt.printf("test int div %d != 5 failed\n",a)
        os.exit(1)
    }
    // e /= 25
    // if  e != 25 {
        // fmt.printf("test int div %d != 25 failed\n",e)
        // os.exit(1)
    // }
    fmt.printf("test int div %d  success\n",a)
}
// 对字符串做运算不做任何操作 都返回0
func test_string(){
    a = "abc"
    a /= 1
    if  a != 0 {
        fmt.printf("test string div %d != 0 failed\n",a)
        os.exit(1)
    }
    // e /= "abc"
    // if  e != "abc" {
        // fmt.printf("test string div %s != abc failed\n",e)
        // os.exit(1)
    // }
    fmt.printf("test string div %d  success\n",a)
}
func test_char2_div(){
    fmt.println("test_char2_div ")
    //test char & char  => int
    c1  = 'd' 
    c1 /= 'D'
    v  = 100 / 68
    if c1 == v {} else {
        os.panic("c1:%d should be %d",c1,v)  
    }
    //char & string     => unsupport
    //char to int        => int
    c1  = 'd' 
    c1 /= 68
    if c1 == v {} else {
        os.panic("c1:%d should be %d",c1,v)
    }
    c1  = 68 
    c1 /= 'd'
    if c1 == 68 / 100 {} else {
        os.panic("c1:%d should be %d",c1,v)
    }
    fmt.println("test_char2_div success")
}
// 除法测试
func main(){
    test_int()
    test_string()
    test_char2_div()
}