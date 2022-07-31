
use fmt
use os

func test_int(){
    //   0 0 1 0
    a = 2
    //   0 0 1 0
    b = 2
    //   1 0 0 0
    a <<= b
    if  a != 8 {
        fmt.println("test int shift left agn %d != 8 failed\n",a)
        os.exit(1)
    }
    c = 0
    a <<= c
    if  a != 8 {
        fmt.println("test int shift left agn %d != 8 failed\n",a)
        os.exit(1)
    }
    e <<= 1
    if  e != 1 {
        fmt.println("test int shift left agn %d != 1 failed\n",e)
        os.exit(1)
    }
    fmt.println("test int shift left agn %d  success\n",e)
}
func test_string(){
    a = "abc"
    a <<= 1
    if  a != 0 {
        fmt.println("test string shift left agn %d != 0 failed\n",a)
        os.exit(1)
    }
    a <<= "sdfdsf"
    if  a != 0 {
        fmt.println("test string shift left agn %d != 0 failed\n",a)
        os.exit(1)
    }
    c <<= "abc"
    if  c != "abc" {
        fmt.println("test string shift left agn %s != abc failed\n",c)
        os.exit(1)
    }
    fmt.println("test string shift left agn %d  success\n",a)
}

func main(){
    test_int()
    test_string()
}