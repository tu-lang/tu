
use fmt
use os

func test_int(){
    a = 10
    b = 10
    a *= b
    if  a != 100 {
        fmt.println("test int mul agn %d != 100 failed\n",a)
        os.exit(1)
    }
    c = 10
    a *= c
    if  a != 1000 {
        fmt.println("test int mul agn %d != 1000 failed\n",a)
        os.exit(1)
    }
    e *= 10
    if  e != 10 {
        fmt.println("test int mul agn %d != 10 failed\n",e)
        os.exit(1)
    }
    fmt.println("test int mul agn %d  success\n",e)
}

func test_string(){
    a = "abc"
    a *= 1
    if  a != "abc" {
        fmt.println("test string mul agn %s != abc failed\n",a)
        os.exit(1)
    }
    a *= 2
    if  a != "abcabc" {
        fmt.println("test string mul agn %s != abcabc failed\n",a)
        os.exit(1)
    }
    c *= "abc"
    if  c != "abc" {
        fmt.println("test string mul agn %s != abc failed\n",c)
        os.exit(1)
    }
    fmt.println("test string mul agn %s  success\n",a)
}

// 注意目前 乘法运算 需要留空格
// a = b * 1  correct
// a = b *1   wrong
func main(){
    test_int()
    test_string()
}