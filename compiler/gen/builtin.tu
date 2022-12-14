use fmt
use parser.package
use ast
use std
use utils

class BuiltinFuncExpr : ast.Ast {
    funcname  = funcname
	expr from
	func init(funcname,line,column){
		super.init(line,column)
	}
}
BuiltinFuncExpr::compile(ctx){
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
			isobj = false
			type_id = 0
			if type(this.expr) == type(VarExpr) {
				ve = this.expr
				if typeids[ve.varname] != null {
					type_id = typeids[ve.varname]
				}else {
					packagename = GP().import[ve.package]
					if package.packages[packagename] != null {
						s = null
						if ( (s = package.packages[packagename].getClass(ve.varname)) && s != null ) {
							type_id = s.type_id
						}else{
							this.expr.compile(ctx)
							isobj = true
						}
					}else{
						this.expr.compile(ctx)
						isobj = true
					}
				}
			}else{
				this.expr.compile(ctx)
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
	this.check(type(this.expr) != type(DoubleExpr))

	// %rax
	ret = this.expr.compile(ctx)

	tk<i32> = ast.I64
	if ret != null {
		match type(ret){
			type(VarExpr): {
				if ret.type >= ast.I8 && ret.type <= ast.U64 
				tk = ret.type
			}
			type(StructMemberExpr) : {
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
			}
			type(ChainExpr) : {
				ce = ret
				if ce.ret == null {
					this.panic("struct chain exp: something wrong here :%s\n",ret.toString())
				}
				if type(ce.last) == type(MemberCallExpr) {
					tk = ast.U64
				}else if type(this.expr) == type(AddrExpr){
				}else{
					compile.LoadMember(ce.ret)
					tk = ce.ret.type
				}
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
        return True
    }
    return False
}