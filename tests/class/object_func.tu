
use fmt
use os

class Http {
    request
    response
    func test_member(){
        fmt.println("[object] test member")
        if  this.request != "request" {
            fmt.println("[object] test member failed this.request != request")
            os.exit(1)
        }
        fmt.println("[object] test member success")
    }
    func test_func_arg(arg){
        fmt.println("[object] test func arg")
        if  this.request != "request" {
            fmt.println("[object] test member failed this.request != request")
            os.exit(1)
        }

        if  arg != "args" {
            fmt.println("[object] test func arg failed arg != args")
            os.exit(1)
        }
        fmt.println("[object] test func arg success")
    }
}

func extern_func(){
    return "extern_func"
}
Http::test_memberfunc(){
    fmt.println("test_memberfunc")
    if this.fc() != "extern_func" {
        os.die("should be extern_func")
    }
    fmt.println("test_memberfunc success",this.fc())
}
func main(){
    a = new Http()
    a.request = "request"
    // 成员函数调用测试
    a.test_member()
    // 成员函数参数测试
    a.test_func_arg("args")
    //成员变量当做成员函数调用
    a. fc = extern_func
    a.test_memberfunc()
}