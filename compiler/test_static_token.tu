use compiler.parser
use compiler.test
use os
use compiler.ast
use compiler.parser.package
use compiler.parser.scanner

class Empty{}
func test(){
	filecase = "./compiler/test/case"
	reader<scanner.ScannerStatic> = new scanner.ScannerStatic(filecase,new Empty())

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