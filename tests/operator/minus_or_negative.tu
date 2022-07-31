
use fmt
use os

func test_int(){
    fmt.println("test int minus or negative")

    a = 1 + -1
    if  a != 0 {
        fmt.println("test 1 -1 != 0 failed")
        os.exit(1)
    }
    a = 1 - 1
    if  a != 0 {
        fmt.println("test 1 - 1 != 0 failed")
        os.exit(1)
    }

    a = 1 + 1
    if  a != 2 {
        fmt.println("test 1 1 != 2 failed")
        os.exit(1)
    }
    fmt.println("test int passed!")
}
func test_string(){
    fmt.println("test string add operate by compiler")
    a = 100 + "test"
    if  a != "100test" {
        fmt.println("test 100 test != 100test failed")
        os.exit(1)
    }
    fmt.println("test string add operate by compiler passed")
}
func test_arg(str){
    fmt.print("test string arg:",str,"\n")
    if  str != "3str1str2str34str4" {
        fmt.println("test str arg failed! str:",str)
        os.exit(1)
    }
    fmt.println("test string arg passed")

}


func main(){
    test_int()
    test_string()
    test_arg(1 + 2 + "str1" + "str2" + "str3" + 4 + "str4")
}