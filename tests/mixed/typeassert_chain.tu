use fmt

mem Value{
	i64 type
	i64 data
}
mem Str{
	i8* a
	i32 b
	i32 c
}
Str::test(){
	fmt.println(int(this.b))
	return this.b
}
func test(v<Value>){
	ret<i8> = v.data.(Str).test()
	if ret == 10 {} else os.die(" v.data.test() != 10")

	if v.data.(Str).test() == ret  {} else os.die("v.data.test != 10")
	
	v.data.(Str).c = 333
	ret = 333
	if v.data.(Str).c == 333 {} else os.die("v.data.c != 333")
	fmt.println("test success")
}

// 链尾类型断言：a.b.(T) 断言后不再接成员访问，断言作用于链条累计到的值本身
func test_chain_end(v<Value>){
	// 链尾 mem 断言：v.data 是 i64 位，断言回 Str 堆对象
	s<Str> = v.data.(Str)
	if s.b == 10 {} else os.die("chain-end mem assert: s.b != 10")

	// 链尾基础类型断言：读出字段值并断言为 i64
	n<i64> = v.type.(i64)
	if n == 5 {} else os.die("chain-end base assert: type != 5")

	fmt.println("chain-end assert success")
}

func main(){
	b = new Value{
		type: 5,
		data: new Str{
			b: 10
		}
	}
	test(b)
	test_chain_end(b)
}