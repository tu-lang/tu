
use fmt

//!
func test_lognot(){
	a = true
	if !a {
		os.die("not true")
	}
	b = false
	if !b != true {
		os.die("should true")
	}
	fmt.println("test lognot ! success")
}
//~
func test_bitnot(){
	//1010 1010 == 170
	a = 170
	//0101 0101 == -171
	b = ~a
	//FIXME: 
	if b != -171 {
		os.die("b should be 85 actl:" + b)
	}
	fmt.println("test bitnot success")
}
func main(){
	test_lognot()
	test_bitnot()
}