use parser
use test
use os
use ast

func test(){
	p = new parser.Parser("./test/case",null,"main","main")
	reader = p.scanner

	for v  : test.token {
		if *v != reader.scan(){
			os.dief(
				"token err: expect %s cur:%s lex:%s",
				ast.getTokenString(*v) ,
				ast.getTokenString(reader.curToken),
				reader.curLex
			)
		}
		fmt.printf("pass token:%s type:%s\n",reader.curLex,ast.getTokenString(reader.curToken))
	}

}
func main(){
	test()
}