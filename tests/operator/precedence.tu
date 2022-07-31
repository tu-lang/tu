use fmt
use os
func gen100(){
	return 100
}
func test_base(){
	fmt.println("test base")
	a = 3 b = 4
	// test (n + n1) * n2
	c = ( a + b) * 5
	fmt.assert(c , 35," (3 + 4) * 5 should be 35")
	c = a + b * 5
	fmt.assert(c , 23," 3 + 4 * 5 should be 23")
	// mulit complex
	d = ( (a+b) * 5) * ((10 - a) * b)
	//d = ( (3+4)*5) * ( (10 - 3) * 4)) 
	//d = ( 35) * 28 = 980 
	fmt.assert(d , 980,"d should be 980")

	if (a = gen100()) && a == 100 {

	}else{
		os.die("a should be 100")
	}

	fmt.println("test base successfully")
}

func test_if(){
	fmt.println("test if")
	a = 1
	b = 2
	if ( a == 1 || b == 3) && (a == 3 || b == 2) {
	}else{
		os.die("should be true")
	}

	fmt.println("test if successfully")
}
func test_while(){
	fmt.println("test while")
	c = 'b'
	count = 1
	while (
		(c >= 'a' && c <= 'z') || 
		(c >= 'A' && c <= 'Z') || 
		(c >= '0' && c <= '9') ){
		count += 1
		c = '2'
		if count == 3 break
	}
	if count != 3 {
		os.die("count should be 3")
	}
	if c != '2' {
		os.die("c should be 2")
	}

	fmt.println("test while successfully")
}
func test_for(){
	fmt.println("test for ")

	b = 5
	for(i = 0 ; (i <= 3 || b == 1) && (i >= 5) ; i +=1 ) {
		os.die("should not be here")
	}
	fmt.println("test for successfully")
}
func main(){
	test_base()
	test_if()
	test_while()
	test_for()
}