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

fn toBinExpr(expr){
	be = new BinaryExpr(expr.line,expr.column)
    be.lhs = expr
    be.opt = ast.GT
	i = new IntExpr(expr.line,expr.column)
    i.lit = "0"
    be.rhs = i
    return be
}

FunCallExpr::argGen(ctx , arg, i, fc){
	ret = this.argCast(ctx, arg, i , fc)
	paramVar = null
	if i < std.len(fc.params_order_var)
		paramVar = fc.params_order_var[i]
		
	if paramVar != null && paramVar.structtype {
		if ast.isfloattk(paramVar.type)
			compile.Pushf(paramVar.type)
		else 
			compile.Push()
	}else if ret != null {
		ty = ret.getType(ctx)
		if ast.isfloattk(ty)
			compile.Pushf(ty)
		else
			compile.Push()
	}else {
		compile.Push()
	}
}

FunCallExpr::argCast(ctx , arg, i,fc){
	ret = null
	paramVar = null
	if i < std.len(fc.params_order_var)
		paramVar = fc.params_order_var[i]

	if paramVar != null && paramVar.structtype && std.empty(paramVar.structname) && ast.isbase(paramVar.type) {
        op = new OperatorHelper()
        op.ltoken = paramVar.type
		op.opt    = ast.ILLEGAL_END
        op.ctx    = ctx
        op.staticCompile(arg)
		if paramVar.pointer 
        	compile.Cast(op.rtoken,ast.I64)
		else 
			compile.Cast(op.rtoken,paramVar.type)
        return ret
    }
    return arg.compile(ctx,true)
}

