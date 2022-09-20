
use fmt
use os

func test_int(){
    a = 10
    b = 10
    a = a * b 
    if  a != 100 {
        fmt.printf("test int mul %d != 100 failed\n",a)
        os.exit(1)
    }
    c = 10
    a = a * c
    if  a != 1000 {
        fmt.printf("test int mul %d != 1000 failed\n",a)
        os.exit(1)
    }
    e = 10 * 10
    if  e != 100 {
        fmt.printf("test int mul %d != 100 failed\n",e)
        os.exit(1)
    }
    fmt.printf("test int mul %d  success\n",e)
}
// 1. string * string == string + string
// 2. string * int    == (string + string)*int
func test_string(){
    a = "abc"
    a = a * 1
    if  a != "abc" {
        fmt.printf("test string mul %s != abc failed\n",a)
        os.exit(1)
    }
    a = a * 2
    if  a != "abcabc" {
        fmt.printf("test string mul %s != abcabc failed\n",a)
        os.exit(1)
    }
    a = 2 * a
    if  a != "abcabcabcabc" {
        fmt.printf("test string mul %s != abcabcabcabc failed\n",a)
        os.exit(1)
    }
    c = "abc" * "abc"
    if  c != "abcabc" {
        fmt.printf("test string mul %s != abcabc failed\n",c)
        os.exit(1)
    }
    fmt.printf("test string mul %s  success\n",a)
}

// test
func test_intp(str){
    if  str != "test" {
        fmt.printf("test string mul %s != test failed\n",str)
        os.exit(1)
    }
    fmt.printf("test string mul %s != test success\n",str)
}
func test_char2_mul(){
    fmt.println("test_char2_mul")
    //test char * char  => char + char  => string
    c1 = 'd' # 100
    c2 = 'D' # 68
    if c1 * c2 ==  "dD" {fmt.println("c1*c2")} else {
        os.panic("c1*c2:%s should be dD",c1 * c2)  
    }
    if c2 * c1 ==  "Dd" {fmt.println("c2*c1")} else {
        os.panic("c2*c1:%s should be dD",c2 * c1)  
    }
    //char * int        => 'b' * 3 => string("bbb")
    if 'b' * 3 == "bbb" {fmt.println("b * 3")} else {
        os.panic("b * 3:%s should be bbb",'b' * 3)
    }
    if 5 * 'x' == "xxxxx"{fmt.println("5 * x")} else {
        os.panic("5 * x:%s should be xxxxx",5 * 'x')
    }
    //char * string => char + string
    if 'b' * "cd" == "bcd" {fmt.println("b * cd")} else {
        os.panic("b * cd:%s == bcd",'b' * "cd")
    }
    //string * char => string + char
    if "ab" * 'c' == "abc" {fmt.println("ab * c")} else {
        os.panic("ab * c:%s == abc","ab" * "c")
    }
    fmt.println("test_char2_mul success")
}
// 注意目前 乘法运算 需要留空格
// a = b * 1  correct
// a = b *1   wrong
func main(){
    test_int()
    test_string()
    test_intp("test" *1)
    test_char2_mul()
}