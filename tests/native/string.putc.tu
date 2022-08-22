use std
use string
Null<i64> = null

func test_puchar_native(){
	s<i8*> = string.stringempty()
	l<i32> = string.stringlen(s)
	if l != 0 {
		os.die("len should be 0")
	}
	//put 10 char
	p<i8*> = "0123456789"
	for i<i32> = 0 ; i < 10 ; i += 1 {
		s = string.stringputc(s , *p)
		p += 1
	}
	cc<i8> = '\\'
	s = string.stringputc(s,cc)
	l = string.stringlen(s)
	if l != 11 {
		os.panic("l should be 10")
	}
	if std.strcmp(s,*"0123456789\\") != Null {
		os.die("s should be 0123456789\\")
	}
	fmt.println("test native put char success ")
}
func test_putchar_dyn(){
	b = "test"
	b += '\\'
	b += '9'
	b += 's'
	if b != "test\\9s" {
		os.die("b should be test\\9s")
	}
	fmt.printf("test dyn put char success %s\n",b)
}
func main(){
	test_puchar_native()
	test_putchar_dyn()
}