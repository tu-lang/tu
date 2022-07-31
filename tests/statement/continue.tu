
use fmt

func test_continue(){
    a = 10
    while a {
        a = a - 1
        if  a == 5 {
            continue
        }
        fmt.println("continue a=%d\n",a)
    }
}


func main(){
    test_continue()
}