use string
use std
use compiler.ast
use compiler.parser.scanner
use compiler.utils
use compiler.gen

Parser::parseTypeAssert(lastdot){
	utils.debugf("Parser::parseTypeAssert() lastdot:%d",lastdot)
	reader<scanner.ScannerStatic> = this.scanner
	ta = null
	if reader.curToken == ast.LPAREN {
		ta = new gen.TypeInfo(this.line,this.column)
		reader.scan()//eat (
		this.check(reader.curToken == ast.VAR || this.isbase(),"a.(?) must be var")
		ta.name = reader.curLex.dyn()
		if reader.curToken == ast.VAR {
			ta.setMemType()
		}
		reader.scan()//eat first var
		if reader.curToken == ast.DOT {
			reader.scan()//eat .
			this.check(reader.curToken == ast.VAR || this.isbase(),"a.(,?) must be var")
			ta.pkg = ta.name
			ta.name = reader.curLex.dyn()
			reader.scan()//eat last
		}
		this.check(reader.curToken == ast.RPAREN,"a.(,)  wrong")
		reader.scan()//eat )

		if ta.memType() {
			if compile.phase == compile.FunctionPhase {
				ta.st = package.getStruct(ta.pkg,ta.name)
				this.check(ta.st != null, "type mem info not define")
			}
		}
		if lastdot {
			this.check(reader.curToken == ast.DOT,"next typeassertexpr can't be nothing")//must be dot
			reader.scan()//eat.
		}
	}
	return ta
}

Parser::parseVarStack(expr){
    this.expect(ast.COLON,"sould be : in stack var declare")
	reader<scanner.ScannerStatic> = this.scanner
    reader.scan()
    expr.stack = true
    expr.stacksize = 1
    if reader.curToken != ast.GT {
        this.expect(ast.INT,"must be int (var<i8:-int-)")
		expr.stacksize = string.tonumber(reader.curLex.dyn())
        if expr.stacksize == 0 
            this.panic("stack size can't be 0")
        reader.scan()
    }
}