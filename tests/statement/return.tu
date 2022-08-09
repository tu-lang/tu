
use fmt
use os

func test_int(b){
    fmt.printf("test int return  %d \n",b)
    if  b != 1 {
        fmt.printf("Error %d\n",b)
        os.exit(1)
    }
    return 2
}
func test_string(str){
    fmt.printf("test string return  %s \n",str)
    return str + "return"
}
func main(){
    a = 1
    b = test_int(a)
    if  b != 2 {
        fmt.printf("Error %d\n",b)
        os.exit(1)
    }
    fmt.printf("test int return success ret:%d\n",b)

    if  a != 1 {
        fmt.printf("Error %d\n",a)
        os.exit(1)
    }

    str = test_string("str-")
    if  str != "str-return" {
        fmt.printf("Error %s\n",str)
        os.exit(1)
    }
    fmt.printf("test string return success ret:%s\n",str)
}