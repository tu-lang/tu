
use fmt
use os

func test_string()
{
    a = "stringa"
    b = "stringb"
    if  a != "stringa" {
        fmt.print("failed a == stringa ",a)
        os.exit(1)
    }
    if  b != "stringb" {
        fmt.print("failed b == stringb ",b)
        os.exit(1)
    }
    a += b

    if  a != "stringastringb" {
        fmt.print("failed a += b ",a)
        os.exit(1)
    }
    fmt.print("success string + string ",a)

}
func test_string_int(num,str){
    nstr = num + str + num
    if  nstr != "99test99" {
        fmt.println("failed num + str ",nstr)
        os.exit(1)
    }
    fmt.print("success num + str == ",nstr)
}
func test_index(){
    fmt.println("test string index")
    str = "abcde"
    if str[0] != 'a' os.die("stro[0] should be a")
    if str[1] != 'b' os.die("stro[1] should be b")
    if str[2] != 'c' os.die("stro[2] should be c")
    if str[3] != 'd' os.die("stro[3] should be d")
    if str[4] != 'e' os.die("stro[4] should be e")
    //out
    if str[5] != 0   os.die("stro[5] should be outbound")
    fmt.println("test string index success")
}
func main(){
    test_string()
    test_string_int(99,"test")
    test_index()
}
