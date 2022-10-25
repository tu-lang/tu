use fmt


mem Test {
	i64 a,b
	Inner inner
}
mem Inner {
	i32 a,b
	i8  c,d
	i8  f[3]
	i64 e
}
Test::test_arr(){
	if this.inner.f[0] == 9 {} else 
		os.die("this.inner.f[0] != 9")
	if this.inner.f[1] == 5 {} else 
		os.die("this.inner.f[1] != 5")
	if this.inner.f[2] == 2 {} else 
		os.die("this.inner.f[1] != 5")
	
	this.inner.d = 33
	this.inner.e = 44

	this.inner.f[0] = 99
	this.inner.f[1] = 55
	this.inner.f[2] = 22
	if this.inner.f[0] == 99 {} else 
		os.die("this.inner.f[0] != 99")
	if this.inner.f[1] == 55 {} else 
		os.die("this.inner.f[1] != 55")
	if this.inner.f[2] == 22 {} else 
		os.die("this.inner.f[2] != 22")

	if this.inner.d == 33 {} else os.die("this.inner.d != 33")
	if this.inner.e == 44 {} else os.die("this.inner.e != 44")
	return this.inner.f[2]
}
func test_chain_index(){
	var<Test> = new Test {
		inner: Inner {
			f : [9,5,2]
		}
	}
	ret<i8> = var.test_arr()
	if ret == 22 {} else os.die("ret != 22")
	fmt.println("test_chain index success")
}
func main(){
	test_chain_index()
}