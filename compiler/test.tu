use parser
use parser.scanner
use std
use runtime

func test(){
	p = new parser.Parser("./main.tu",null,"main","main")
	s = p.scanner

	True = true
	while True {
		s.scan()
		fmt.println(s.curLex)
	}
}
func main(){
	// test()
	cn = 's'
	b = cn <= '9'
	fmt.println(cn,b)
}