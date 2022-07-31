
use fmt
use os

func test_int()
{
    a = 10
    b = 20
    if  a != 10 {
        fmt.println("failed a")
        os.exit(1)
    }
    if  b != 20 {
        fmt.println("failed b")
        os.exit(1)
    }
    a += b

    if  a != 30 {
        fmt.println("failed a += b")
        os.exit(1)
    }
    a -= b
    if  a != 10 {
        fmt.println("failed a -= b")
        os.exit(1)
    }
    a *= b
    if  a != 200 {
        fmt.println("failed a *= b")
        os.exit(1)
    }
    a /= b
    if  a != 10 {
        fmt.println("failed b /= a",a)
        os.exit(1)
    }
    fmt.print("success int + int ",a," ",b)

}
func test_string_int(num,str){
    nstr = num + str
    if  nstr != "99test" {
        fmt.println("failed num + str ",nstr)
        os.exit(1)
    }
    fmt.print("success num + str == ",nstr)
}

func main(){
    test_int()
    test_string_int(99,"test")
}
