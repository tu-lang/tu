use string
use std
use ast
use parser.scanner
use utils
use gen

Parser::parseTypeAssert(lastdot){
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