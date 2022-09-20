
use fmt
use os

// 测试 int +=
func test_int2_add()
{
    fmt.println("test int- add agn\n")
    a = 10
    b = 20
    a += b
    if  a == 30 {
        fmt.printf("test %d + %d add agn ok\n",a,b)
    }else{
        fmt.printf("test %d + %d failed\n",a,b)
        os.exit(1)
    }
    fmt.printf("test %d + %d add agn ok\n",a,b)

    c += b
    if  c != 20 {
        fmt.printf("test %d += %d add agn failed\n",c,b)
        os.exit(1)
    }
    fmt.printf("test %d += %d add agn success\n",c,b)
}
func test_string2_add(){
    fmt.println("test string- add agn\n")
    a = "variable-a "
    b = "variable-b "
    a += b
    if  a == "variable-a variable-b " {
        fmt.println("test string-string add agn ok\n")
    }else{
        fmt.println("test string-string add agn failed\n")
        os.exit(1)
    }
    c += b
    if  c == "variable-b " {
        fmt.println("test string-int add agn ok\n")
    }else{
        fmt.printf("test string-int add agn failed %s\n",c)
        os.exit(1)
    }

}
func test_char2_add(){
    fmt.println("test_char2_add agn")
    //test char to char  => string
    c1 = 'd' # 100
    c1 += 'D' # 68
    if c1 != "dD" {
        os.panic("c1:%s should be dD",c1)  
    }
    //char to string     => string
    c1 = 'd'
    c1 += "c12c"
    if c1 != "dc12c" {
        os.panic("c1:%s should be dc12c",c1)
    }
    c1 = "xx12x"
    c1 += '9'
    if c1 != "xx12x9" {
        os.panic("c1:%s should be xx12x9",c1)
    }
    //char to int        => int
    c1 = 100
    c1 += 'D' #68
    if c1 != 168 {
        os.panic("cd:%d should be 168",c1)
    }
    c1 = 'D'
    c1 += 100
    if c1 != 168 {
        os.panic("cd:%d should be 168",c1)
    }
    fmt.println("test_char2_add agn success")
}
func main(){
    test_int2_add()
    test_string2_add()
    test_char2_add()
}

