use fmt
use parser.package

class BuiltinFuncExpr : ast.Ast {
    funcname expr from
	func init(line,column){
		super.init(line,column)
	}
}
BuiltinFuncExpr::compile(ctx){
	if this.funcname == "sizeof" {
		this.check(
			type(this.expr) == type(VarExpr),
			"must be varexpr in sizeof()"
		)
		ve = this.expr
		m = package.getStruct(ve.package,ve.varname)
		this.check(m != null,"mem not exist")

		compile.writeln("   mov $%d , %%rax",m.size)
		return null
	}
	this.check(type(this.expr) != type(IntExpr))
	this.check(type(this.expr) != type(StringExpr))
	this.check(type(this.expr) != type(ArrayExpr))
	this.check(type(this.expr) != type(MapExpr))
	this.check(type(this.expr) != type(NullExpr))
	this.check(type(this.expr) != type(CharExpr))
	this.check(type(this.expr) != type(DoubleExpr))

	// %rax
	ret = this.expr.compile(ctx)

	tk<i32> = ast.I64
	if (ret == null){
	}else if  type(ret) == type(VarExpr) {
		if ret.type >= ast.I8 && ret.type <= ast.U64 
			tk = ret.type
	}
	else if type(ret) == type(StructMemberExpr) {
		sm = ret
		m = sm.ret
		if m == null {
			this.panic("del ref can't find the struct member:%s",
				this.expr.toString()
			)
		}
		if type(this.expr) != type(DelRefExpr) {
			compile.LoadMember(m)
		}
		tk = m.type
	}else if type(ret) == type(ChainExpr) {
		ce = ret
		if ce.ret == null {
			this.panic("struct chain exp: something wrong here :%s\n",ret.toString())
		}
		compile.LoadMember(ce.ret)
		tk = ce.ret.type
	}

	if this.funcname == "string" {
		internal.newobject2(ast.String)
		return null
	}else if this.funcname == "int" {
		//TODO: cast i8 i16 i 32  to  i64
		compile.Cast(tk,parser.I64)
		internal.newobject2(ast.Int)
		return null
	}
}
BuiltinFuncExpr::toString(){
	return fmt.sprintf("BuiltinFuncExpr:%s(%s)"
		this.funcname,
		this.expr.toString("")
	)
}

BuiltinFuncExpr::isMem(ctx){
    if this.funcname == "sizeof" {
        return True
    }
    return False
}