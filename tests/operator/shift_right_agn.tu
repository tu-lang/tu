
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
        fmt.printf("test int shift right agn %d != 2 failed\n",a)
        os.exit(1)
    }
    c = 0
    a >>= 0
    if  a != 2 {
        fmt.printf("test int shift right agn %d != 2 failed\n",a)
        os.exit(1)
    }
    e >>= 32
    if  e != 32 {
        fmt.printf("test int shift right agn %d != 8 failed\n",e)
        os.exit(1)
    }
    fmt.printf("test int shift right agn %d  success\n",e)
}
func test_string(){
    a = "abc"
    a >>= 1
    if  a != 0 {
        fmt.printf("test string shift right agn %d != 0 failed\n",a)
        os.exit(1)
    }
    a >>= "sdfdsf"
    if  a != 0 {
        fmt.printf("test string shift right agn %d != 0 failed\n",a)
        os.exit(1)
    }
    c >>= "abc"
    if  c != "abc" {
        fmt.printf("test string shift right agn %s != abc failed\n",c)
        os.exit(1)
    }
    fmt.printf("test string shift right agn %d  success\n",a)
}
func test_char2_shift_right(){
    fmt.println("test_char2_shift_right")
    //test char << char  => string
    c1 = 'd' 
    c1 >>= 'D'
    if c1 == "dD" {} else {
        os.panic("c1:%s should be dD",c1)  
    }
    //char << string     => unsupport
    //char << int        => int
    c1 = 'd'
    c1 >>= 68
    if c1 == 100 >> 68 {} else {
        os.panic("c1:%d should be %d",'d' >> 68 , 100 >> 68)
    }
    fmt.println("test_char2_shift right success")
}
func main(){
    test_int()
    test_string()

    test_char2_shift_right()
}