
use fmt
use time
use os

func test_while(){
    a = 4
    while a != 2 {
        fmt.printf("a=%d\n",a)
        //time.sleep(1)
        a = a - 1
    }
        //time.sleep(3)
    if  a != 2 {
        fmt.printf("failed a:%d should be 2 \n",a)
        os.exit(1)
    }
    fmt.printf("success a:%d should be 2 \n",a)
}


func main(){
    test_while()
}