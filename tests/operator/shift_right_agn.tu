
use fmt
use os

func test_int(){
    //   0 0 1 0
    a = 8
    //   1 0 0 0
    b = 2
    //   0 0 1 0
    a >>= b
    if  a != 2 {
        fmt.println("test int shift right agn %d != 2 failed\n",a)
        os.exit(1)
    }
    c = 0
    a >>= 0
    if  a != 2 {
        fmt.println("test int shift right agn %d != 2 failed\n",a)
        os.exit(1)
    }
    e >>= 32
    if  e != 32 {
        fmt.println("test int shift right agn %d != 8 failed\n",e)
        os.exit(1)
    }
    fmt.println("test int shift right agn %d  success\n",e)
}
func test_string(){
    a = "abc"
    a >>= 1
    if  a != 0 {
        fmt.println("test string shift right agn %d != 0 failed\n",a)
        os.exit(1)
    }
    a >>= "sdfdsf"
    if  a != 0 {
        fmt.println("test string shift right agn %d != 0 failed\n",a)
        os.exit(1)
    }
    c >>= "abc"
    if  c != "abc" {
        fmt.println("test string shift right agn %s != abc failed\n",c)
        os.exit(1)
    }
    fmt.println("test string shift right agn %d  success\n",a)
}

func main(){
    test_int()
    test_string()

}