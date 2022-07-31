
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
        fmt.println("test %d + %d add ok\n",a,b)
    }else{
        fmt.println("test %d + %d failed\n",a,b)
        os.exit(1)
    }
    fmt.println("test %d + %d add ok\n",a,b)
    c += b
    if  c != 50 {
        fmt.println("test %d += %d add failed\n",c,b)
        os.exit(1)
    }
    fmt.println("test %d += %d add success\n",c,b)
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
        fmt.println("test string-int add failed %s\n",c)
        os.exit(1)
    }

}
func test_addintcall(a){
    if  a == 3 {
        fmt.println("test addintcall  ok 1+2=%d\n",a)
    }else{
        fmt.println("test addintcall  failed\n")
        os.exit(1)
    }

}

func test_addstringcall(a){
    if  a == "test" {
        fmt.println("test addstringcall  ok tes+t=%s\n",a)
    }else{
        fmt.println("test addstringcall  failed\n")
        os.exit(1)
    }

}

// 测试 +
// 测试 +=
func main(){
    test_int2_add()
    test_string2_add()
    test_addintcall(1+2)
    test_addstringcall("tes" + "t")
}

