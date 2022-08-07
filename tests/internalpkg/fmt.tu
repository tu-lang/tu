
use fmt

func println(){
    a = -1323
    if  a {
        fmt.println("a is negative not should be here ",a,"wrong")
    }else{
        fmt.println("ok ",a,"it's clear")
    }
}
func test_sprintf(){
    fmt.println("test sprintf")
    //normal test
    //movq -16(%rsp) %rbp
    str = fmt.sprintf("%s %i(%%rsp) %%rbp","movq",-16)
    if str != "movq -16(%rsp) %rbp" {
        os.die("assert failed")
    }
    //stack params test,over 6 params
    dst = "first second third 1 2 -3 fourth fifth sixth"
    str = fmt.sprintf("%s %s %s %i %i %i %s %s %s"
        "first","second","third",
        1,2,-3,
        "fourth","fifth","sixth"
    )
    if dst != str {
        fmt.println(str)
        os.die("assert failed")
    }

    fmt.println("test sprintf success")
}
func main(){
    println()
    test_sprintf()
}

