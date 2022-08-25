
use fmt
use os

class File {
    a = 5
    b = "test"
    obj
    func f(){
        this.b = "test2"
    }
}

func newinit_test(){
    // member test
    obj = new File()
    if obj.b != "test" {
        os.die("obj.b != test")
    }
    obj.obj = new File()
    //FIXME: obj.obj.f() => obj.obj.f(obj.obj) not obj.obj.f(obj)
    // obj.obj.f()
    //test again
    if obj.b != "test" {
        os.die("obj.b != test")
    }
    // if obj.obj.b != "test2" {
        // fmt.println(obj.obj.b)
        // os.die("obj.obj.b != test2")
    // }
    // test arr
    arr = [0]
    arr[0] = new File()
    if arr[0].a != 5 {
        os.die("arr[0].a != 5")
    }
    fmt.println("test newinit success")


}
func main(){
    // 测试 成员变量的查询和更新
    test_member_get_or_update()
    newinit_test()
}

class Http {
    // 可以不必显示定义成员变量
    // 可以动态定义变量
    request
    response
    func handler(){
    }
}
func test_member_get_or_update(){
    fmt.println("[object] test member get and update")

    b  = new Http()
    b.request = 1
    if  b.request != 1 {
        fmt.println("test member failed b.request:" + b.request + " != 1")
        os.exit(1)
    }
    b.request = "test"
    if  b.request != "test" {
        fmt.println("test member failed b.request:" + b.request + " != test")
        os.exit(1)
    }

    b.request = ["test",1,10000]
    fmt.println(b.request)

    fmt.println("[object] test dyanmic member get and update")
    b.notdefine = 1
    if  b.notdefine != 1 {
        fmt.println("test member failed b.notdefine:" + b.notdefine + " != 1")
        os.exit(1)
    }
    b.notdefine = "test"
    if  b.notdefine != "test" {
        fmt.println("test member failed b.notdefine:" + b.notdefine + " != test")
        os.exit(1)
    }

    b.notdefine = ["test",1,10000]
    fmt.println(b.notdefine)
    fmt.println("test daynamic member and static member get&update all pass")
}