
use fmt
use os

//测试 值比较
func test_int_notequal(num){
    fmt.println("test int var not equal...\n")
    if   num != 100 {
        fmt.printf("test %d != 100 failed...\n",num)
        os.exit(1)
    }else{
        fmt.printf("test %d != 100 success...\n",num)
    }
    if   num != 10 {
        fmt.printf("test %d != 10  success...\n",num)
    }else{
        fmt.printf("test %d != 10  failed...\n",num)
        os.exit(1)
    }
}

func test_string_notequal(str){
    fmt.println("test string var not equal...\n")

    if   str != "notequal" {
        fmt.printf("test %s != notequal failed...\n",str)
        os.exit(1)
    }else{
        fmt.printf("test %s != notequal success...\n",str)
    }

    if   str != 100 {
        fmt.printf("test %s != 100 success...\n",str)
    }else{
        fmt.printf("test %s != 100 success...\n",str)
        os.exit(1)
    }
}
func test_char2_notequal(){
    fmt.println("test_char2_notequal ")
    //test char & char  => int
    c1 = 'd' 
    v  = 'd'
    if c1 != v  {
        os.panic("c1:%d should be %d",c1,v)  
    }
    //char & string     => unsupport
    //char to int        => int
    if c1 != 100 {
        os.panic("c1:%d should be %d",c1,100)
    }
    if 100 != c1 {
        os.panic("c1:%d should be %d",c1,100)
    }
    fmt.println("test_char2_notequal success")
}
func main(){
    //测试 数字
    test_int_notequal(100)
    //测试字符串
    test_string_notequal("notequal")
    test_char2_notequal()
}

