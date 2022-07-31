
use fmt
use os

func test_int(){
    a = 10
    b = 10
    a = a * b 
    if  a != 100 {
        fmt.println("test int mul %d != 100 failed\n",a)
        os.exit(1)
    }
    c = 10
    a = a * c
    if  a != 1000 {
        fmt.println("test int mul %d != 1000 failed\n",a)
        os.exit(1)
    }
    e = 10 * 10
    if  e != 100 {
        fmt.println("test int mul %d != 100 failed\n",e)
        os.exit(1)
    }
    fmt.println("test int mul %d  success\n",e)
}
// 1. string * string == string + string
// 2. string * int    == (string + string)*int
func test_string(){
    a = "abc"
    a = a * 1
    if  a != "abc" {
        fmt.println("test string mul %s != abc failed\n",a)
        os.exit(1)
    }
    a = a * 2
    if  a != "abcabc" {
        fmt.println("test string mul %s != abcabc failed\n",a)
        os.exit(1)
    }
    a = 2 * a
    if  a != "abcabcabcabc" {
        fmt.println("test string mul %s != abcabcabcabc failed\n",a)
        os.exit(1)
    }
    c = "abc" * "abc"
    if  c != "abcabc" {
        fmt.println("test string mul %s != abcabc failed\n",c)
        os.exit(1)
    }
    fmt.println("test string mul %s  success\n",a)
}

// test
func test_intp(str){
    if  str != "test" {
        fmt.println("test string mul %s != test failed\n",str)
        os.exit(1)
    }
    fmt.println("test string mul %s != test success\n",str)
}

// 注意目前 乘法运算 需要留空格
// a = b * 1  correct
// a = b *1   wrong
func main(){
    test_int()
    test_string()
    test_intp("test" *1)
}