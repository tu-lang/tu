
use fmt
use os

func test_int(){
    a = 0
    b = 0
    if  a || b {
        fmt.print("test int logand  0 || 0 failed",a)
        os.exit(1)
    }
    b = 1
    if  a || b {
        fmt.print("test int logand  0 || 1 success",a)
    }else{
        fmt.print("test int logand  0 || 1 failed",a)
        os.exit(1)
    }
    
    if  0 || 0 {
        fmt.print("test int logand  0 || 0 failed")
        os.exit(1)
    }
    if  1 || 0 {
        fmt.print("test int logand  1 || 0 success")
    }else{
        fmt.print("test int logand  1 || 0 failed")
        os.exit(1)
    }
    fmt.print("test int logand  success")
}
func test_string(){
    a = ""
    b = ""
    if  a || b {
        fmt.print("test string logand  ||  failed")
        os.exit(1)
    }
    b = "o"
    if  a || b {
        fmt.print("test string logand  ||  successed")
    }else{
        fmt.print("test string logand  ||  failed",a)
        os.exit(1)
    }

    if  "" || "" {
        fmt.print("test string logand  || failed")
        os.exit(1)
    }
    fmt.print("test string logand  success")
}

func main(){
    test_int()
    test_string()

}