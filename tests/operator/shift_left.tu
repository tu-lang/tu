
use fmt
use os

func test_int(){
    //   0 0 1 0
    a = 2
    //   0 0 1 0
    b = 2
    //   1 0 0 0
    a = a << b
    if  a != 8 {
        fmt.println("test int shift left %d != 8 failed\n",a)
        os.exit(1)
    }
    c = 0
    a = a << c
    if  a != 8 {
        fmt.println("test int shift left %d != 8 failed\n",a)
        os.exit(1)
    }
    e = a << 1
    if  e != 16 {
        fmt.println("test int shift left %d != 16 failed\n",e)
        os.exit(1)
    }
    fmt.println("test int shift left %d  success\n",e)
}
func test_string(){
    a = "abc"
    a = a << 1
    if  a != 0 {
        fmt.println("test string shift left %d != 0 failed\n",a)
        os.exit(1)
    }
    a = 2 << "sdfdsf"
    if  a != 0 {
        fmt.println("test string shift left %d != 0 failed\n",a)
        os.exit(1)
    }
    c = "abc" << "abc"
    if  c != 0 {
        fmt.println("test string shift left %d != 0 failed\n",c)
        os.exit(1)
    }
    fmt.println("test string shift left %d  success\n",a)
}

// test
func test_intp(str){
    if  str != 0 {
        fmt.println("test string shift left %d != test failed\n",str)
        os.exit(1)
    }
    fmt.println("test string shift left %d != test success\n",str)
}

func main(){
    test_int()
    test_string()
    test_intp("sdfsd" << 100)
}