
use fmt

func test_while_break(){
    a = 10
    while a {
        if  a == 5 {
            fmt.println("should break %d\n",a)
            break
        }
        a = a - 1
        fmt.println("break %d\n",a)
    }
}
func break_double(){
    b = 1
    while b {
        c = 1
        fmt.println("outside\n")
        while c {
            fmt.println("inside\n")
            break
        }
        break
    }
}

func main(){
    test_while_break()
    //break_double()
}