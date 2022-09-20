
use fmt
use os

func test_int(){
    a = 10
    if  a != 10 {
        os.exit(1)
    }
    a -= 1
    if  a != 9 {
        fmt.printf("test int minus agn %d != 9 failed\n",a)
        os.exit(1)
    }
    fmt.printf("test int minus agn %d != 9 success\n",a)
}
// 对字符串做运算不做任何操作
func test_string(){
    a = "abc"
    a -= 1
    if  a != "abc" {
        fmt.printf("test string minus agn %s != abc failed\n",a)
        os.exit(1)
    }
    fmt.printf("test string minus agn %s != abc success\n",a)
}
func test_char2_minus_agn(){
    fmt.println("test_char2_minus agn ")
    //test char - char  => int
    c1  = 'd' # 100
    c1 -= 'D' # 68
     
    if c1  ==  32 {} else {
        os.panic("c1-c2:%d should be 32",c1)  
    }
    //char - int        => int
    c1 = 100
    c1 -= 'D'
    if c1 == 32 {} else {
        os.panic("100-D:%d should be 32",c1)
    }
    c1 = 'D'
    c1 -= 100
    if c1 == -32 {} else {
        os.panic("D - 100:%d should be -32",c1)
    }
    fmt.println("test_char2_minus agn success")
}
// 注意目前 减运算 需要留空格
func main(){
    test_int()
    test_string()
    test_char2_minus_agn()
}