
use fmt
use os

class Http {
    // 可以不必显示定义成员变量
    // 可以动态定义变量
    request
    response
    func handler(){

    }
}

func main(){
    // 测试 未定义成员变量的二元操作符如:+ - * \ ...等等
    test_member_binary_operator_undefine()
    // 测试 成员变量的二元操作符如:+ - * \ ...等等
    test_member_binary_operator()
}

func test_member_binary_operator_undefine(){
    fmt.println("[object] test undefine member binary operator")
    b  = new Http()

    a = b.undefine_int1 + 1
    if  a != 1 {
        fmt.println("test failed undefine_int1")
        os.exit(1)
    }
    a = b.undefine_int2 * 3
    if  a != 0 {
        fmt.println("test failed undefine_int2",a)
        os.exit(1)
    }
    a = b.undefine_int3 - 3
    if  a != -3 {
        fmt.println("test failed undefine_int3",a)
        os.exit(1)
    }
    a = b.undefine_int4 / 3
    if  a != 0 {
        fmt.println("test failed undefine_int4")
        os.exit(1)
    }
    a = b.undefine_int5 << 1
    if  a != 0 {
        fmt.println("test failed undefine_int5")
        os.exit(1)
    }
    a = b.undefine_int6 >> 1
    if  a != 0 {
        fmt.println("test failed undefine_int6")
        os.exit(1)
    }
    a = b.undefine_int7 & 1
    if  a != 0 {
        fmt.println("test failed undefine_int7")
        os.exit(1)
    }
    a = b.undefine_int8 | 1
    if  a != 1 {
        fmt.println("test failed undefine_int8")
        os.exit(1)
    }
    fmt.println("[object] test undefine member binary operator all pass")
}
func test_member_binary_operator(){
    fmt.println("[object] test  member binary operator")
    b  = new Http()

    b.request = 9
    a = b.request + 1
    if  a != 10 {
        fmt.println("test failed request +")
        os.exit(1)
    }
    a = b.request * 3
    if  a != 27 {
        fmt.println("test failed request * ")
        os.exit(1)
    }
    a = b.request - 3
    if  a != 6 {
        fmt.println("test failed request -")
        os.exit(1)
    }
    a = b.request / 3
    if  a != 3 {
        fmt.println("test failed request /")
        os.exit(1)
    }
    a = b.request << 2
    if  a != 36 {
        fmt.println("test failed request <<")
        os.exit(1)
    }
    a = b.request >> 1
    if  a != 4 {
        fmt.println("test failed request >>")
        os.exit(1)
    }
    // 9 & 1 = 0
    a = b.request & 1
    if  a != 1 {
        fmt.println("test failed request &",a)
        os.exit(1)
    }
    a = b.request | 1
    if  a != 9 {
        fmt.println("test failed request")
        os.exit(1)
    }
    fmt.println("[object] test  member binary operator all pass")

}