
use net
use fmt
use os

mem Ip
{
	u32 a
	u16 b,c
}
mem Ip2{
	u16 a[3]
	u16 b
}
func test2(){
	v<Ip> = new Ip
	v.c = 100
	v2<Ip2> = v
	if  v2.b != 100 {
		fmt.println("v2.b should == 100 ",v2.b)
		os.exit(-1)
	}
	fmt.println("test member arr success")
}
func main(){
	test1()
	test2()
}

// 测试内存读写，映射、转换
func test1()
{
	// 申请一份sizeof(net.Ip) 的gc内存
	p<net.Ip> = new net.Ip
	p.identify = 10000
	fmt.assert(int(p.identify),10000)

	// 位的读写
	p.r = 1
	p.d = 1
	p.m = 1
	p.foffset = 3
	fmt.assert(int(p.foffset),3)
	// 重新映射一份结构 测试转换
	p2<Ip> = p
	// u16 r:1
	// u16 d:1
	// u16 m:1
	// u16 foffset:13
	// 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 == 31
	fmt.assert(int(p2.c),31)

	fmt.println(int(p2.a),int(p2.b),int(p2.c))
	fmt.println("test mem successful")
}