
use fmt
use os

func test_int(){
    a = 10
    b = 10
    a &= b
    if  a != 10 {
        fmt.println("test int bitand %d != 10 failed\n",a)
        os.exit(1)
    }
    c = 0
    a &= c
    if  a != 0 {
        fmt.println("test int bitand %d != 0 failed\n",a)
        os.exit(1)
    }
    // 10 & 2 = 2
    e &= 2
    if  e != 2 {
        fmt.println("test int bitand %d != 2 failed\n",e)
        os.exit(1)
    }
    fmt.println("test int bitand %d  success\n",e)
}
func test_string(){
    a = "abc"
    a &= 1
    if  a != 0 {
        fmt.println("test string bitand %s != 0 failed\n",a)
        os.exit(1)
    }
    a &= "sdfdsf"
    if  a != 0 {
        fmt.println("test string bitand %s != 0 failed\n",a)
        os.exit(1)
    }
    fmt.println("test string bitand %d  success\n",a)
}

func main(){
    test_int()
    test_string()
}