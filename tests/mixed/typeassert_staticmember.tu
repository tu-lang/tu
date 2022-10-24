use fmt
use string

mem String {
	i8* inner
}
String::putc(c<i8>){
	this.inner = this.inner.(string.Str).putc(c)
}
String::str(){
	return this.inner
}

func test_S2(){
	a<String> = new String {
		inner : string.empty()
	}
	b<i8> = 'c'
	a.putc(b)
	a.putc(b)
	a.putc(b)
	fmt.println(string.new(a.str()))
	if string.new(a.str()) == "ccc" {} else os.die("String.putc != ccc")
	fmt.println("test String.putc success")
}

func test_S1(){
	// s<t.String> = t.string()
	s<i8*> = string.empty()
	b<i8> = 'c'
	s = s.(string.Str).putc(b)
	s = s.(string.Str).putc(b)
	s = s.(string.Str).putc(b)

	if string.new(s) == "ccc" {} else os.die(" ! ccc")
	fmt.println("test Str.putc success")
}

func main(){
	test_S1()
	test_S2()
}