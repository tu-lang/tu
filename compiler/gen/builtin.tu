use fmt
use compiler.parser.package
use compiler.ast
use std
use compiler.utils
use compiler.compile
use compiler.internal

class BuiltinFuncExpr : ast.Ast {
    funcname  = funcname
	expr from
	func init(funcname,line,column){
		super.init(line,column)
	}
}
BuiltinFuncExpr::compile(ctx,load){
	funcname = this.funcname
	utils.debugf("gen.BuiltinFuncExpr::compile() funcname:%s",funcname)
	match funcname {
		"sizeof" : {
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
		"type": {
			if type(this.expr) == type(VarExpr) {
				ve = this.expr
				if typeids[ve.varname] != null {
					type_id = typeids[ve.varname]
					internal.newobject(ast.Int,type_id)
					return null
				}else {
					pkg = GP().pkg.getPackage(ve.package)
					if pkg != null {
						s = pkg.getClass(ve.varname)
						if s != null {
							compile.writeln("	lea %s(%%rip) , %%rax", s.virtname())
							internal.newobject2(ast.Int)
							return null
						}
					}
				}
			}
			this.expr.compile(ctx,true)
			internal.type_id2()
			return null
		}
		"type2": {
			isobj = false
			type_id = 0
			if type(this.expr) == type(VarExpr) {
				ve = this.expr
				if typeids[ve.varname] != null {
					type_id = typeids[ve.varname]
				}else {
					pkg = GP().pkg.getPackage(ve.package)
					if pkg != null {
						s = pkg.getClass(ve.varname)
						if s != null {
						// if ( (s = package.packages[packagename].getClass(ve.varname)) && s != null ) {
							type_id = s.type_id
						}else{
							this.expr.compile(ctx,true)
							isobj = true
						}
					}else{
						this.expr.compile(ctx,true)
						isobj = true
					}
				}
			}else{
				this.expr.compile(ctx,true)
				isobj = true
			}
			internal.type_id(type_id,isobj)
			return null
		}
	}
	this.check(type(this.expr) != type(IntExpr))
	this.check(type(this.expr) != type(StringExpr))
	this.check(type(this.expr) != type(ArrayExpr))
	this.check(type(this.expr) != type(MapExpr))
	this.check(type(this.expr) != type(NullExpr))
	this.check(type(this.expr) != type(CharExpr))
	this.check(type(this.expr) != type(FloatExpr))

	// %rax
	ret = this.expr.compile(ctx,true)

	tk<i32> = ast.I64
	if ret != null {
		match type(ret){
			type(VarExpr): {
				if ret.type >= ast.I8 && ret.type <= ast.F64
				tk = ret.type
			}
			type(StructMemberExpr) : {
				m = ret.getMember()
				if m == null {
					this.panic("del ref can't find the struct member: " + 
						this.expr.toString()
					)
				}
				tk = m.type
			}
			type(FunCallExpr): tk = ast.U64
			type(ChainExpr) : {
				this.panic(fmt.sprintf("struct chain exp: something wrong here :%s\n",ret.toString()))
			}
		}
	}

	if this.funcname == "string" {
		internal.newobject2(ast.String)
		return null
	}else if this.funcname == "int" {
		//TODO: cast i8 i16 i 32  to  i64
		compile.Cast(tk,ast.I64)
		internal.newobject2(ast.Int)
		return null
	}else if this.funcname == "float" {
		compile.Cast(tk,ast.F64)
		internal.newfloat()
		return null
	}
	return null
}
BuiltinFuncExpr::toString(){
	return fmt.sprintf("BuiltinFuncExpr:%s(%s)"
		this.funcname,
		this.expr.toString("")
	)
}

BuiltinFuncExpr::isMem(ctx){
    if this.funcname == "sizeof" {
        return true
    }
    return false
}