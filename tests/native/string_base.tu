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
	fmt.println("test putstring success")
}

func main(){
	str = test_putc()
	test_putstring(str)
}