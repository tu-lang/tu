use string
use std
use compiler.ast
use compiler.parser.scanner
use compiler.utils
use compiler.gen

Parser::parseTypeAssert(lastdot){
	utils.debugf("Parser::parseTypeAssert() lastdot:%d",lastdot)
	ta = null
	if this.scanner.curToken == ast.LPAREN {
		ta = new gen.TypeAssertExpr(this.line,this.column)
		this.scanner.scan()//eat (
		this.check(this.scanner.curToken == ast.VAR || this.isbase(),"a.(?) must be var")
		ta.name = this.scanner.curLex
		this.scanner.scan()//eat first var
		if this.scanner.curToken == ast.DOT {
			this.scanner.scan()//eat .
			this.check(this.scanner.curToken == ast.VAR || this.isbase(),"a.(,?) must be var")
			ta.pkgname = ta.name
			ta.name = this.scanner.curLex
			this.scanner.scan()//eat last
		}
		this.check(this.scanner.curToken == ast.RPAREN,"a.(,)  wrong")
		this.scanner.scan()//eat )
		if lastdot {
			this.check(this.scanner.curToken == ast.DOT,"next typeassertexpr can't be nothing")//must be dot
			this.scanner.scan()//eat.
		}
	}
	return ta
}

Parser::parseVarStack(expr){
    this.expect(ast.COLON,"sould be : in stack var declare")
    this.scanner.scan()
    expr.stack = true
    expr.stacksize = 1
    if this.scanner.curToken != ast.GT {
        this.expect(ast.INT,"must be int (var<i8:-int-)")
		expr.stacksize = string.tonumber(this.scanner.curLex)
        if expr.stacksize == 0 
            this.panic("stack size can't be 0")
        this.scanner.scan()
    }
}