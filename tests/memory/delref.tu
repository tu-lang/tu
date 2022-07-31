
use fmt
use os

// 1. 测试动态变量的解引用
// 2. 测试变量的引用
func test_var(){
    var1 = 100
    var2 = int(*var1)
    if  var1 != var2 {
        fmt.print("*var test failed ",var1,var2,"\n")
        os.exit(-1)
    }
    fmt.println(var1,var2)

    var1 = -100
    var2 = int(*var1)
    if  var1 != var2 {
        fmt.print("*var test failed ",var1,var2,"\n")
        os.exit(-1)
    }

    // 测试变量的引用
    s_var<i8> = 10
    s_var_p<i8*> = &s_var
    *s_var_p = 30
    if  s_var != 30 {
        fmt.println("s_var should be 30")
        os.exit(-1)
    }
    if  s_var_p != &s_var {
        fmt.println("s_var_p should be &s_var")
        os.exit(-1)
    }
    // _{{var}}
    _var<i8*> = &s_var
    if *_var != 30 {
        os.die("*_var should be 30" + int(*_var))
    }
    fmt.println("test del ref  var success")
}
mem T {
    i8* a
    u64 b
}
// FIXME: 当变量名为 mem 名时要优化异常处理
func test_memeory(){
    var<T> = new T
    var.a = &var.b

    var.b = -100
    if   int(*var.a)  != -100 {
        fmt.print("*memory test failed ",int(var.b),int(*var.a),"\n")
        os.exit(-1)
    }
    fmt.println("test memory del ref success")
}
mem T2{
    u64* a
    i8* b
    i8* c
    i64 d
}
func test_multi(){
    var<T2> = new T2
    var.a = &var.b
    var.b = &var.c
    var.c = &var.d

    var.d = -100
    
    delref = int(***var.a)
    if  delref != -100 {
        fmt.print("multi delref ***(var) test failed ",int(var.d),delref,"\n")
        os.exit(-1)
    }
    fmt.println("test del ref (***p) successful")
}
func main(){
    test_var()
    test_memeory()
    test_multi()
    fmt.println("test del ref (*p) successful")

}