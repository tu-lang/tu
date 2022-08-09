
use fmt
use time
use os


func test_tri_for(){
    arr = []
    for(a = 1 ; a < 10 ; a += 2){
        arr[] = a
    }
    i = 0
    for(a = 1 ; a < 10 ; a += 2){
        if  arr[i] != a {
            fmt.printf("failed arr[i]:%d should be %d \n",i,a)
            os.exit(1)
        }
        fmt.printf("arr[%d]=%d a=%d\n",i,arr[i],a)
        i += 1
    }
    //FIXME: fmt.println("yes) may cause dead lock
    fmt.println("test for statment passed!")
}


func main(){
    test_tri_for()
}