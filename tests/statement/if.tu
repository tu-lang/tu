
use fmt
use os

func test_no_brace(){
	arr = [1,100,"test","else"]

	if arr[2] == "test1"     os.die("not test1")
	else if arr[3] == "else" fmt.println("yes")

	if arr[1] == 102 os.die("not 102")
	else if false os.die("not false")
	else fmt.println("yes")

	if arr[2] == "te" os.die("not te")
	else if arr[3] == "else" fmt.println("yes")
	else os.die("not this one")

    if arr[2] != "test" os.die("should be test")

    # 没有括号的时候只能生效一行语句，而不是表达式
    f = func(){
        var = 100
        if var == 200 os.die("not 200")
        else if var == 100 return 100
        return 300
    }
    if f() != 100 os.die("shoudl be 100") 
    
	fmt.println("else if test success")
}
# 测试有括号的情况
func test_has_brace(){
    a = 1
    if  a == 1 {
        fmt.println("OK\n")
        if  a != 10 {
            fmt.println("OK\n")
        }else{
            os.die("failed")
        }
    }else{
        fmt.println("OK\n")
        os.exit(1)
    }
    //测试 elseif

    map = {"one":100 , "second":333 , 44:55}
    if map["one"] == 101 {
        os.die("not this")
    }else if map["second"] == 3334 {
        os.die("not 333")
    }else if map[44] == 55 {
        fmt.println("this one")
    }
    fmt.println("test if else if has brace success")

}

func main(){
    test_has_brace()
    test_no_brace()
}

