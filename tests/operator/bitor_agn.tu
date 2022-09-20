
use fmt
use os

func test_int(){
    //   1 1 0 1
    a = 13
    //   0 0 1 0
    b = 2
    //   1 1 1 1
    a |= b
    if  a != 15 {
        fmt.printf("test int bitor %d != 15 failed\n",a)
        os.exit(1)
    }
    c = 0
    a |= c
    if  a != 15 {
        fmt.printf("test int bitor %d != 15 failed\n",a)
        os.exit(1)
    }
    e |= 16
    if  e != 16 {
        fmt.printf("test int bitor %d != 16 failed\n",e)
        os.exit(1)
    }
    fmt.printf("test int bitor %d  success\n",e)
}
func test_string(){
    a = "abc"
    a |= 1
    if  a != 0 {
        fmt.printf("test string bitor %s != 0 failed\n",a)
        os.exit(1)
    }
    a |= "sdfdsf"
    if  a != 0 {
        fmt.printf("test string bitor %s != 0 failed\n",a)
        os.exit(1)
    }
    c |= "abc"
    if  c != "abc" {
        fmt.printf("test string bitor %s != abc failed\n",c)
        os.exit(1)
    }
    fmt.printf("test string bitor %d  success\n",a)
}

func test_char2_bitor(){
    fmt.println("test_char2_bitor agn")
    //test char & char  => int
    c1  = 'd' 
    c1 |= 'D'
    v  = 100 | 68
    if c1 == v {} else {
        os.panic("c1:%d should be %d",c1,v)  
    }
    //char & string     => unsupport
    //char to int        => int
    c1  = 'd' 
    c1 |= 68
    if c1 == v {} else {
        os.panic("c1:%d should be %d",c1,v)
    }
    c1  = 68 
    c1 |= 'd'
    if c1 == v {} else {
        os.panic("c1:%d should be %d",c1,v)
    }
    fmt.println("test_char2_bitor agn success")
}
func main(){
    test_int()
    test_string()
    test_char2_bitor()
}