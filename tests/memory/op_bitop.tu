

use fmt
use os

// << <<=
func test_shift_left() {
	fmt.println("test shift left and assign")
	v<i8> = 1
	v = v << 1
	v = v << 1
	fmt.assert(int(v),4)
	v = v << 1
	fmt.assert(int(v),8)
	if   v != 8 {
		fmt.println("v should eq 8 ",v)
		os.exit(-1)
	}

	v <<= 1
	fmt.assert(int(v),16)
	v <<= 1
	fmt.assert(int(v),32)
	if  v != 32 {
		fmt.println("v should eq 32",v)
		os.exit(-1)
	}
	fmt.println("test left shift and assign success")
}
// >> >>=
func test_shift_right() {
	fmt.println("test shift right and assign")
	v<i8> = 32
	v = v >> 1 
	fmt.assert(int(v),16)
	v = v >> 1
	fmt.assert(int(v),8)
	if  v != 8 {
		fmt.println("v should be 8",v)
		os.exit(-1)
	}

	v >>= 1
	fmt.assert(int(v),4)
	v >>= 1
	fmt.assert(int(v),2)
	v >>= 1
	fmt.assert(int(v),1)
	if  v != 1 {
		fmt.println("v should be 1",v)
		os.exit(-1)
	}
	fmt.println("test right shift and assign success")

}
func test_and(){
	fmt.println("test_and")
	a<i8> = 10
    b<i8> = 10
    a = a & b
    if  a != 10 {
        fmt.println("test int bitand %d != 10 failed\n",int(a))
        os.exit(1)
    }
    c<i8> = 0
    a &= c
    if  a != 0 {
        fmt.println("test int bitand %d != 0 failed\n",int(a))
        os.exit(1)
    }
    // 10 & 2 = 2
    e<i8> = b & 2
    if  e != 2 {
        fmt.println("test int bitand %d != 2 failed\n",int(e))
        os.exit(1)
    }
    fmt.println("test int bitand %d  success\n",int(e))
}
func test_or(){
    //   1 1 0 1
    a<i8> = 13
    //   0 0 1 0
    b<i8> = 2
    //   1 1 1 1
    a = a | b
    if  a != 15 {
        fmt.println("test int bitor %d != 15 failed\n",int(a))
        os.exit(1)
    }
    c = 0
    a |= *c
    if  a != 15 {
        fmt.println("test int bitor %d != 15 failed\n",int(a))
        os.exit(1)
    }
    e<i8> = a | 16
    if  e != 31 {
        fmt.println("test int bitor %d != 31 failed\n",int(e))
        os.exit(1)
    }
    fmt.println("test int bitor %d  success\n",int(e))
}
func test_lognot(){
	a<i8> = 100
	if !a {
		os.die("not true")
	}
	b = 0
	if !b != 1 {
		os.die("should true")
	}

	fmt.println("test lognot ! success")
}
//~
func test_bitnot(){
	//1010 1010 == 170
	a<i8> = 170
	//0101 0101 == 85
	b<i8> = ~a
	if b != 85 {
		os.die("b should be 85")

	}
	c<i8> = 4
	d<i8> = c & ~a
	if d != 4 {
		os.die("d should be 4")
	}
	fmt.println("test bitnot ~ success")
}
func main(){
	fmt.println("test bit op << || <<= || >> || >>=")
	test_shift_left()
	test_shift_right()
	test_and()
	test_or()
	test_lognot()
	test_bitnot()
}