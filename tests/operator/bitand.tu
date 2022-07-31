
use fmt
use os

func test_int(){
    a = 10
    b = 10
    a = a & b
    if  a != 10 {
        fmt.println("test int bitand %d != 10 failed\n",a)
        os.exit(1)
    }
    c = 0
    a = a & c
    if  a != 0 {
        fmt.println("test int bitand %d != 0 failed\n",a)
        os.exit(1)
    }
    // 10 & 2 = 2
    e = b & 2
    if  e != 2 {
        fmt.println("test int bitand %d != 2 failed\n",e)
        os.exit(1)
    }
    fmt.println("test int bitand %d  success\n",e)
}
func test_string(){
    a = "abc"
    a = a & 1
    if  a != 0 {
        fmt.println("test string bitand %s != 0 failed\n",a)
        os.exit(1)
    }
    a = 2 & "sdfdsf"
    if  a != 0 {
        fmt.println("test string bitand %s != 0 failed\n",a)
        os.exit(1)
    }
    c = "abc" & "abc"
    if  c != 0 {
        fmt.println("test string bitand %s != 0 failed\n",c)
        os.exit(1)
    }
    fmt.println("test string bitand %d  success\n",a)
}

// test
func test_intp(str){
    if  str != 0 {
        fmt.println("test string bitand %d != test failed\n",str)
        os.exit(1)
    }
    fmt.println("test string bitand %d != test success\n",str)
}

func main(){
    test_int()
    test_string()
    test_intp("test" & 1)
}