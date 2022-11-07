use fmt
use os

func test_chars(){
	a = 'a'
	b = 'a'
	_a<i64> = a
	_b<i64> = b
	if _a == _b {} else os.panic(
		"a != a"
	)

	c = '?'
	d = '?'
	_c<i64> = c
	_d<i64> = d
	if _c == _d {} else os.panic(
		"? != ?"
	)
	if _a == _c os.panic("a == ?")
	fmt.println("test chars pool success")
}

func main(){
	test_chars()
}