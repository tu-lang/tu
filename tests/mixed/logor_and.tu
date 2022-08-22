use fmt
use os

func retfalse(){ 
	return false
}
func rettrue(){ 
	return true 
}
//test && ||
func test_log_and_or(){
	b = null
	c<i8> = 10 
	// native type
	// next expression will be handled by special native compiler
	// b == null   => dyn type
	// c == 10     => native type
	// b == null && c == 10 => native type
	if b == null && c == 10 {} else {
		os.die("b should be null")
	}
	if b != null && c == 10 {
		os.die("b should not be null")
	}
	if !retfalse() && c == 10 {} else {
		os.die("!fasle should be true")
	}

	if b == null || c == 11 {} else {
		os.die("b should be null")
	}
	if b != null || c == 11 {
		os.die("b should not be null")
	}
	fmt.println("test log_and_or success")
}

func main(){
	test_log_and_or()
}