
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

// 注意目前 减运算 需要留空格
func main(){
    test_int()
    test_string()
}