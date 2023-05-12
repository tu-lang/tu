use compiler.parser
use compiler.test
use os
use compiler.ast
use compiler.parser.package
use compiler.parser.scanner


func test(){
	mpkg = new package.Package("main","main",false)
	p = new parser.Parser("./compiler/test/case",mpkg)
	reader<scanner.ScannerStatic> = p.scanner

	for v  : test.token {
		if *v != reader.scan(){
			os.dief(
				"token err: expect %s cur:%s lex:%s",
				ast.getTokenString(*v) ,
				ast.getTokenString(reader.curToken),
				reader.curLex.dyn()
			)
		}
		fmt.printf("pass token:%s type:%s\n",reader.curLex.dyn(),ast.getTokenString(reader.curToken))
	}

}
func main(){
	test()
}