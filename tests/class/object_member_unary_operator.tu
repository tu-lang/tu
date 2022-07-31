
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
    // 测试 未定义成员变量的一元操作符如:+= -= *= \= ...等等
    test_member_unary_operator_undefine()
    // 测试 成员变量的一元操作符如:+= -= *= \= ...等等
    test_member_unary_operator()
}

func test_member_unary_operator_undefine(){
    fmt.println("[object] test undefine member unary operator")
    b  = new Http()

    b.undefine_int1 += 1
    if  b.undefine_int1 != 1 {
        fmt.println("test failed undefine_int1")
        os.exit(1)
    }
    b.undefine_int2 *= 3
    if  b.undefine_int2 != 0 {
        fmt.println("test failed undefine_int2",b.undefine_int2)
        os.exit(1)
    }
    b.undefine_int3 -= 3
    if  b.undefine_int3 != -3 {
        fmt.println("test failed undefine_int3",b.undefine_int3)
        os.exit(1)
    }
    b.undefine_int4 /= 3
    if  b.undefine_int4 != 0 {
        fmt.println("test failed undefine_int4")
        os.exit(1)
    }
    b.undefine_int5 <<= 1
    if  b.undefine_int5 != 0 {
        fmt.println("test failed undefine_int5")
        os.exit(1)
    }
    b.undefine_int6 >>= 1
    if  b.undefine_int6 != 0 {
        fmt.println("test failed undefine_int6")
        os.exit(1)
    }
    b.undefine_int7 &= 1
    if  b.undefine_int7 != 0 {
        fmt.println("test failed undefine_int7")
        os.exit(1)
    }
    b.undefine_int8 |= 1
    if  b.undefine_int8 != 1 {
        fmt.println("test failed undefine_int8")
        os.exit(1)
    }
    fmt.println("[object] test undefine member unary operator all pass")
}
func test_member_unary_operator(){
    fmt.println("[object] test  member unary operator")
    b  = new Http()

    b.request = 9
    b.request += 1
    if  b.request != 10 {
        fmt.println("test failed request +=")
        os.exit(1)
    }
    b.request *= 3
    if  b.request != 30 {
        fmt.println("test failed request *= ")
        os.exit(1)
    }
    b.request -= 3
    if  b.request != 27 {
        fmt.println("test failed request -=")
        os.exit(1)
    }
    b.request /= 3
    if  b.request != 9 {
        fmt.println("test failed request /=")
        os.exit(1)
    }
    b.request <<= 2
    if  b.request != 36 {
        fmt.println("test failed request <<=")
        os.exit(1)
    }
    b.request >>= 1
    if  b.request != 18 {
        fmt.println("test failed request >>=")
        os.exit(1)
    }
    // 18 & 1 = 0
    b.request &= 1
    if  b.request != 0 {
        fmt.println("test failed request &=",b.request)
        os.exit(1)
    }
    b.request |= 1
    if  b.request != 1 {
        fmt.println("test failed request")
        os.exit(1)
    }
    fmt.println("[object] test  member unary operator all pass")

}