
use fmt
use os

func test_int(){
    a = 10
    b = 10
    a *= b
    if  a != 100 {
        fmt.printf("test int mul agn %d != 100 failed\n",a)
        os.exit(1)
    }
    c = 10
    a *= c
    if  a != 1000 {
        fmt.printf("test int mul agn %d != 1000 failed\n",a)
        os.exit(1)
    }
    // e *= 10
    // if  e != 10 {
        // fmt.printf("test int mul agn %d != 10 failed\n",e)
        // os.exit(1)
    // }
    fmt.printf("test int mul agn %d  success\n",a)
}

func test_string(){
    a = "abc"
    a *= 1
    if  a != "abc" {
        fmt.printf("test string mul agn %s != abc failed\n",a)
        os.exit(1)
    }
    a *= 2
    if  a != "abcabc" {
        fmt.printf("test string mul agn %s != abcabc failed\n",a)
        os.exit(1)
    }
    // c *= "abc"
    // if  c != "abc" {
        // fmt.printf("test string mul agn %s != abc failed\n",c)
        // os.exit(1)
    // }
    fmt.printf("test string mul agn %s  success\n",a)
}
func test_char2_mul_agn(){
    fmt.println("test_char2_mul agn")
    //test char * char  => char + char  => string
    c1  = 'd' # 100
    c1 *= 'D' # 68
    if c1 ==  "dD" {fmt.println("c1*c2")} else {
        os.panic("c1*c2:%s should be dD",c1 )  
    }
    c2 = 'D'
    c2 *= 'd'
    if c2  ==  "Dd" {fmt.println("c2*c1")} else {
        os.panic("c2*c1:%s should be dD",c2)  
    }
    //char * int        => 'b' * 3 => string("bbb")
    c1 = 'b'
    c1 *= 3
    if c1 == "bbb" {fmt.println("b * 3")} else {
        os.panic("b * 3:%s should be bbb",c1)
    }
    c1 = 5
    c1 *= 'x'
    if c1 == "xxxxx"{fmt.println("5 * x")} else {
        os.panic("5 * x:%s should be xxxxx",5 * 'x')
    }
    //char * string => char + string
    c1 = 'b'
    c1 *= "cd"
    if c1 == "bcd" {fmt.println("b * cd")} else {
        os.panic("b * cd:%s == bcd",'b' * "cd")
    }
    //string * char => string + char
    c1 = "ab"
    c1 *= 'c'
    if c1 == "abc" {fmt.println("ab * c")} else {
        os.panic("ab * c:%s == abc","ab" * "c")
    }
    fmt.println("test_char2_mul agn success")
}
// 注意目前 乘法运算 需要留空格
// a = b * 1  correct
// a = b *1   wrong
func main(){
    test_int()
    test_string()
    test_char2_mul_agn()
}