
use fmt
use os

func test_int(){
    a = 10
    b = 10
    a &= b
    if  a != 10 {
        fmt.printf("test int bitand %d != 10 failed\n",a)
        os.exit(1)
    }
    c = 0
    a &= c
    if  a != 0 {
        fmt.printf("test int bitand %d != 0 failed\n",a)
        os.exit(1)
    }
    // 10 & 2 = 2
    // e &= 2
    // if  e != 2 {
        // fmt.printf("test int bitand %d != 2 failed\n",e)
        // os.exit(1)
    // }
    fmt.printf("test int bitand %d  success\n",a)
}
func test_string(){
    a = "abc"
    a &= 1
    if  a != 0 {
        fmt.printf("test string bitand %s != 0 failed\n",a)
        os.exit(1)
    }
    a &= "sdfdsf"
    if  a != 0 {
        fmt.printf("test string bitand %s != 0 failed\n",a)
        os.exit(1)
    }
    fmt.printf("test string bitand %d  success\n",a)
}
func test_char(){
    fmt.println("test_char agn")
    //test char & char  => int
    c1  = 'd'
    c1 &= 'D'
    v  = 100 & 68
    if c1 == v {} else {
        os.panic("c1:%d should be %d",c1,v)  
    }
    //char & string     => unsupport
    //char to int        => int
    c1  = 'd'
    c1 &= 68
    if c1 == v {} else {
        os.panic("c1:%d should be %d",c1,v)
    }
    c1  = 68
    c1 &= 'd'
    if c1 == v {} else {
        os.panic("c1:%d should be %d",c1,v)
    }
    fmt.println("test_char agn success")
}
func main(){
    test_int()
    test_string()
    test_char()
}