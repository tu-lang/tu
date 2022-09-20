
use fmt
use os

func test_int(){
    a = 10
    if  a != 10 {
        os.exit(1)
    }
    a = a - 1
    if  a != 9 {
        fmt.printf("test int minus %d != 9 failed\n",a)
        os.exit(1)
    }
    fmt.printf("test int minus %d != 9 success\n",a)
}
// 对字符串做运算不做任何操作
func test_string(){
    a = "abc"
    a = a - 1
    if  a != "abc" {
        fmt.printf("test string minus %s != abc failed\n",a)
        os.exit(1)
    }
    fmt.printf("test string minus %s != abc success\n",a)
}

func test_intp(str){
    if  str != "test-1" {
        fmt.printf("test string minus %s != abc failed\n",str)
        os.exit(1)
    }
    fmt.printf("test string minus %s != abc success\n",str)
}
func test_char2_minus(){
    fmt.println("test_char2_minus")
    //test char - char  => int
    c1 = 'd' # 100
    c2 = 'D' # 68
    if c1 - c2 ==  32 {} else {
        os.panic("c1-c2:%d should be 32",c1 - c2)  
    }
    //char - int        => int
    if 100 - 'D' == 32 {} else {
        os.panic("100-D:%d should be 32",100 - 'D')
    }
    if 'D' - 100 == -32 {} else {
        os.panic("D - 100:%d should be -32",'D' - 100)
    }
    fmt.println("test_char2_minus success")
}
// 注意目前 减运算 需要留空格
// a = b - 1  correct
// a = b -1   incorrect
func main(){
    test_int()
    test_string()
    test_intp("test" + -1)
    test_char2_minus()
}