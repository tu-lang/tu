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

func main(){
	b = new Value{
		data: new Str{
			b: 10
		}
	}
	test(b)
}