use string


func test_putc(){
	str<string.String> = string.string()
	str.putc('h'.(i8))
	str.putc('e'.(i8))
	str.putc('l'.(i8))
	str.putc('l'.(i8))
	str.putc('o'.(i8))

	if int(str.len()) == 5 {} else os.die("str.len() should be 5")

	if string.new(str.str()) == "hello" {} else 
		os.die("str.str() != hello")
	fmt.println("test putc success")
	return str
}
func test_putstring(str2){
	str<string.String> = string.string()
	str.putc('w'.(i8))
	str.putc('o'.(i8))
	str.putc('r'.(i8))
	str.putc('l'.(i8))
	str.putc('d'.(i8))

	if int(str.len()) == 5 {} else os.die("str.len() should be 5")

	str.cat(str2)
	if string.new(str.str()) == "worldhello" {} else 
		os.die("str.str() != helloworld")

	str.catstr("-tulang".(i8))
	if string.new(str.str()) == "worldhello-tulang" {} else 
		os.die("str.str() != helloworld-tulang")

	fmt.println("test putstring success")
}
func test_cmpstr_empty(){
	s<string.String> = string.string()
	s.putc('d'.(i8))
	ret<i8> = s.cmpstr("d".(i8))
	if ret == 0 {} else os.die("should be 0")
	True<i32> = 1
	if s.empty() ==  True os.die("should be false")

	s.inner = string.empty()
	if s.empty() == True {} else os.die("should be true")
	fmt.println("test string cmpstr|| empty success")
}
func test_fmt(){
	s<string.Str> = string.stringfmt(
		"%d %d %d %d %d %d %d\n".(i8),
		111.(i8),
		222.(i8),
		333.(i8),
		444.(i8),
		555.(i8),
		666.(i8),
		777.(i8),
	)
	if ( ret<i8> = std.strcmp(s,"111 222 333 444 555 666 777\n".(i8))) == string.Equal {} else {
		os.die("not equal1")
	}
	s = string.stringfmt(
		"%d %s %d".(i8),
		111.(i8),"test".(i8),222.(i8)
	)
	if ( ret<i8> = std.strcmp(s,"111 test 222".(i8))) == string.Equal {} else {
		os.die("not equal2")
	}
	if ( ret<i8> = std.strcmp(s,"111 test 222\n".(i8))) == string.Equal {
		os.die("not should equal2")
	}

	fmt.println("test fmt success")
}
func main(){
	str = test_putc()
	test_putstring(str)
	test_cmpstr_empty()
	test_fmt()
}