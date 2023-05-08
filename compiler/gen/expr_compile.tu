use compiler.ast 
use string

BinaryExpr::expr_compile(){
	utils.debugf("gen.BinaryExpr::expr_compile()")
	left = 0
	right = 0
	match type(this.lhs) {
		type(BinaryExpr) :	left = this.lhs.expr_compile()
		type(VarExpr) : left = this.lhs.expr_compile()
		type(IntExpr) : left = string.tonumber(this.lhs.lit)
		_ :	this.check(false,"unsupport type in Binaryy::expr_compile ")
	}
	match type(this.rhs) {
		type(BinaryExpr) : right = this.rhs.expr_compile()
		type(VarExpr) : right = this.rhs.expr_compile()
		type(IntExpr) : right = string.tonumber(this.rhs.lit)
		_ : this.check(false,"unsupport type in Binaryy::expr_compile ")
	}
	match this.opt {
		ast.ADD :   return left + right
		ast.SUB:   return left - right
		ast.MUL:   return left * right
		ast.DIV:   return left / right
		ast.SHL:   return left << right
		_:    this.check(false,"only support +-*/<< in expr_compile")
	}
}
VarExpr::expr_compile(){
	realvar = GP().getGlobalVar(this.package,this.varname)
	if realvar == null {
		this.check(false,"macro var not exist in mem member define")
	}
	return string.tonumber(realvar.ivalue)
}