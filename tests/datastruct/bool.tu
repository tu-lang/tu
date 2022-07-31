
use fmt
use os

func main(){
    fmt.println("bool test")

    // 测试 bool 赋值  和 istrue判断
    isbool = true
    if  isbool {
        fmt.println("bool test ok\n")
    }else{
        fmt.println("bool test failed\n")
        os.exit(1)
    }

    // 测试 bool 赋值  和 istrue判断
    isbool = false
    if  isbool {
        fmt.println("bool test failed\n")
        os.exit(1)
    }else{
        fmt.println("bool test ok\n")
    }


}
