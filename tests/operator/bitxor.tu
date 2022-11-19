
use fmt
use os
//0^0=0,0^1=1 0异或任何数，其结果=任何数
//1^0=1,1^1=0 1异或任何数，其结果=任何数取反
func test_int(){
    //   1 1 0 1
    a = 13
    //   0 0 1 1
    b = 3
    //   1 1 1 0
    a = a ^ b 
    if  a != 14 {
        fmt.printf("test int bitxor %d != 14 failed\n",a)
        os.exit(1)
    }
    c = 0
    a = a ^ c
    if  a != 14 {
        fmt.printf("test int bitxor %d != 14 failed\n",a)
        os.exit(1)
    }
    e = a | 16
    if  e != 30 {
        fmt.printf("test int bitxor %d != 30 failed\n",e)
        os.exit(1)
    }
    fmt.printf("test int bitxor %d  success\n",e)
}
func test_string(){
    a = "abc"
    a = a ^ 1
    if  a != 0 {
        fmt.printf("test string bitxor %s != 0 failed\n",a)
        os.exit(1)
    }
    a = 2 ^ "sdfdsf"
    if  a != 0 {
        fmt.printf("test string bitxor %s != 0 failed\n",a)
        os.exit(1)
    }
    c = "abc" ^ "abc"
    if  c != 0 {
        fmt.printf("test string bitxor %s != 0 failed\n",c)
        os.exit(1)
    }
    fmt.printf("test string bitxor %d  success\n",a)
}

// test
func test_intp(str){
    if  str != 0 {
        fmt.printf("test string bitxor %d != test failed\n",str)
        os.exit(1)
    }
    fmt.printf("test string bitxor %d != test success\n",str)
}
func test_char2_bitxor(){
    fmt.println("test_char2_bitxor ")
    //test char & char  => int
    c1 = 'd' ^ 'D'
    v  = 100 ^ 68
    if c1 == v {} else {
        os.panic("c1:%d should be %d",c1,v)  
    }
    //char & string     => unsuppxort
    //char to int        => int
    c1 = 'd' ^ 68
    if c1 == v {} else {
        os.panic("c1:%d should be %d",c1,v)
    }
    c1 = 68 ^ 'd'
    if c1 == v {} else {
        os.panic("c1:%d should be %d",c1,v)
    }
    fmt.println("test_char2_bitxor success")
}
func main(){
    test_int()
    test_string()
    test_intp("test" ^ 1)
    test_char2_bitxor()
}