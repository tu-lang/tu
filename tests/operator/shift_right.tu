
use fmt
use os

func test_int(){
    //   0 0 1 0
    a = 2
    //   1 0 0 0
    b = 8
    //   0 0 1 0
    a = b >> a
    if  a != 2 {
        fmt.printf("test int shift right %d != 2 failed\n",a)
        os.exit(1)
    }
    c = 0
    a = a >> 0
    if  a != 2 {
        fmt.printf("test int shift right %d != 2 failed\n",a)
        os.exit(1)
    }
    e = 32 >> a
    if  e != 8 {
        fmt.printf("test int shift right %d != 8 failed\n",e)
        os.exit(1)
    }
    fmt.printf("test int shift right %d  success\n",e)
}
func test_string(){
    a = "abc"
    a = a >> 1
    if  a != 0 {
        fmt.printf("test string shift right %d != 0 failed\n",a)
        os.exit(1)
    }
    a = 2 >> "sdfdsf"
    if  a != 0 {
        fmt.printf("test string shift right %d != 0 failed\n",a)
        os.exit(1)
    }
    c = "abc" >> "abc"
    if  c != 0 {
        fmt.printf("test string shift right %d != 0 failed\n",c)
        os.exit(1)
    }
    fmt.printf("test string shift right %d  success\n",a)
}

// test
func test_intp(str){
    if  str != 0 {
        fmt.printf("test string shift right %d != test failed\n",str)
        os.exit(1)
    }
    fmt.printf("test string shift right %d != test success\n",str)
}
func test_char2_shift_right(){
    fmt.println("test_char2_shift_right")
    //test char << char  => string
    if 'd' >> 'D' == "dD" {} else {
        os.panic("c1:%s should be dD",'d' >> 'D')  
    }
    //char << string     => unsupport
    //char << int        => int
    if 'd' >> 68 == 100 >> 68 {} else {
        os.panic("c1:%d should be %d",'d' >> 68 , 100 >> 68)
    }
    fmt.println("test_char2_shift right success")
}
func main(){
    test_int()
    test_string()
    test_intp("sdfsd" >> 100)
    test_char2_shift_right()
}