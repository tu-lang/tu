
use fmt
use os

// 测试 int + 
// 测试 int +=
func test_int2_add()
{
    fmt.println("test int- add\n")
    a = 10
    b = 20
    c = a + b
    if  c == 30 {
        fmt.printf("test %d + %d add ok\n",a,b)
    }else{
        fmt.printf("test %d + %d failed\n",a,b)
        os.exit(1)
    }
    fmt.printf("test %d + %d add ok\n",a,b)
    c += b
    if  c != 50 {
        fmt.printf("test %d += %d add failed\n",c,b)
        os.exit(1)
    }
    fmt.printf("test %d += %d add success\n",c,b)
}
func test_string2_add(){
    fmt.println("test string- add\n")
    a = "variable-a "
    b = "variable-b "
    c = a + b 
    if  c == "variable-a variable-b " {
        fmt.println("test string-string add ok\n")
    }else{
        fmt.println("test string-string add failed\n")
        os.exit(1)
    }
    c = a + 10
    if  c == "variable-a 10" {
        fmt.println("test string-int add ok\n")
    }else{
        fmt.printf("test string-int add failed %s\n",c)
        os.exit(1)
    }

}
func test_addintcall(a){
    if  a == 3 {
        fmt.printf("test addintcall  ok 1+2=%d\n",a)
    }else{
        fmt.println("test addintcall  failed\n")
        os.exit(1)
    }

}

func test_addstringcall(a){
    if  a == "test" {
        fmt.printf("test addstringcall  ok tes+t=%s\n",a)
    }else{
        fmt.println("test addstringcall  failed\n")
        os.exit(1)
    }

}
func test_char2_add(){
    fmt.println("test_char2_add")
    //test char to char  => string
    c1 = 'd' # 100
    c2 = 'D' # 68
    if c1 + c2 != "dD" {
        os.panic("c1:%s should be dD",c1 + c2)  
    }
    //char to string     => string
    if c1 + "c12c" != "dc12c" {
        os.panic("c1:%s should be dc12c",c1 + "c12c")
    }
    if "xx12x" + '9' != "xx12x9" {
        os.panic("c1:%s should be xx12x9","xx12x" + '9')
    }
    //char to int        => int
    c1 = 100
    if c1 + 'D' == 168 {} else {
        os.panic("cd:%d should be 168",c1)
    }
    c1 = 'D'
    if c1 + 100 == 168 {} else {
        os.panic("cd:%d should be 168",c1 + 100)
    }
    fmt.println("test_char2_add success")
}

// 测试 +
// 测试 +=
func main(){
    test_int2_add()
    test_string2_add()
    test_addintcall(1+2)
    test_addstringcall("tes" + "t")
    test_char2_add()
}

