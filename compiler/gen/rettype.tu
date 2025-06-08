use compiler.ast
use compiler.utils 
use std

ClosPosExpr::getType(ctx){
	this.panic("getType: unsupport closposexpr")
}
ArgsPosExpr::getType(ctx){
	this.panic("getType: unsupport argsposexpr")
}
StackPosExpr::getType(ctx){
	// this.panic("getType: unsupport stackposexpr")
	return ast.I64
}
NullExpr::getType(ctx){
	return ast.U8
}
BoolExpr::getType(ctx){
	return ast.U8
}
CharExpr::getType(ctx){
	return ast.I8
}
IntExpr::getType(ctx){
	return ast.I64
}
FloatExpr::getType(ctx){
	return ast.F64
}
StringExpr::getType(ctx){
	return ast.U64
}
ArrayExpr::getType(ctx){
	// this.panic("getType: unsupport array\n")
	return ast.I64
}
MapExpr::getType(ctx){
	this.panic("getType: unsupport map\n")
}
KVExpr::getType(ctx){
	this.panic("getType: unsupport kv\n")
}

VarExpr::getType(ctx){
	this.getVarType(ctx,this)
	if this.ret.pointer return ast.U64

	return this.ret.type
}
ClosureExpr::getType(ctx){
	this.panic("getType: unsupport closure\n")
}
StructMemberExpr::getType(ctx){
	m = this.getMember()
	if m.pointer || m.isstruct return ast.U64
	return m.type
}
AddrExpr::getType(ctx){
	return ast.U64
}
DelRefExpr::getType(ctx){
	return this.expr.getType(ctx)
}
IndexExpr::getType(ctx){
	var = new VarExpr(this.varname,this.line,this.column)
    var.package = this.package
	match var.getVarType(ctx,this) {
		ast.Var_Global_Local_Static_Field | ast.Var_Local_Static_Field: {
			sm = new StructMemberExpr(var.package,this.line,this.column)
			sm.member = var.varname
			sm.var    = var.ret
			return sm.getMember().type
		}
	}
	return var.getType(ctx)
}
NewStructExpr::getType(ctx){
	return ast.U64
}
StructInitExpr::getType(ctx){
	this.panic("getType: unsupport struct init \n")
	return ast.U64
}
BinaryExpr::getType(ctx){
	match this.opt {
		ast.LOGNOT | ast.EQ | ast.NE: return ast.I64
		ast.GT | ast.GE | ast.LT | ast.LE: return ast.I64
	}
	if this.opt == ast.LT || this.opt == ast.LOGAND
		return ast.I64	

	if !this.rhs {
		ty = this.lhs.getType(ctx)
		if ast.isfloattk(ty)
			return ast.I64
		return ty
	}
	
	l = this.lhs.getType(ctx)
	r = this.rhs.getType(ctx)
	return utils.max(l,r)
}
FunCallExpr::getType(ctx){
	this.geninit(ctx)
	this.check(this.fcs != null,"must compile first")
	if std.len(this.fcs.returnTypes) != 0 {
		dr = this.fcs.returnTypes[0]
		if dr.baseType() {
			return dr.base
		}
	}
	return ast.I64
}
AssignExpr::getType(ctx){
	return this.lhs.getType(ctx)
}
NewClassExpr::getType(ctx){
	this.panic("getType: unsupport new class\n")
}
BuiltinFuncExpr::getType(ctx){
	return ast.U64
	this.panic("getType: unsupport builtin\n")
}
NewExpr::getType(ctx){
	return ast.U64
}
MemberExpr::getType(ctx){
	var = GP().getGlobalVar("",this.varname)
	if var == null
		var = ctx.getLocalVar(this.varname)
	if var == null {
		this.panic("getTYpe: var is null")
	}
	if var.structtype {
		mexpr = new StructMemberExpr(var.varname,this.line,this.column)
		mexpr.var = var
		mexpr.member = this.membername
		return mexpr.getType(ctx)
	}else if this.tyassert != null {

		mexpr = new StructMemberExpr(var.varname,this.line,this.column)
		vv = new VarExpr("",0,0)
		vv.structpkg = this.tyassert.pkg
		vv.structname = this.tyassert.name
		vv.structtype = true
		mexpr.var = vv
		mexpr.member = this.membername
		return mexpr.getType(ctx)
	}
	return var.getType(ctx)
}
MemberCallExpr::getType(ctx){
    if this.varname != "" {
        this.check(false,"getType in null varname membercall")
    }
	fc = null
    if this.staticCall != null {
		fc = this.staticCall.getFunc(this.membername)
    }else if this.obj != null {
		s = package.getStruct(this.obj.structpkg,this.obj.structname)
		this.check(s != null,"s == null")
		fc = s.getFunc(this.membername)
	}else if this.tyassert != null {
		s = this.tyassert.getStruct()
		this.check(s != null, "s == null")
		fc = s.getFunc(this.membername)
    }else{
		return ast.U64
	}
	this.check(fc != null, "fc == null")
	if std.len(fc.returnTypes) != 0 {
		dr = fc.returnTypes[0]
		if dr.baseType() {
			return dr.base
		}
	}
	return ast.U64
}
MatchCaseExpr::getType(ctx){
	this.panic("getType: unsupport MatchCaseExpr\n")
}
IfCaseExpr::getType(ctx){
	this.panic("getType: unsupport IfCaseExpr\n")
}
LabelExpr::getType(ctx){
	this.panic("getType: unsupport LabelExpr\n")
}

ChainExpr::getType(ctx){
	if !this.ismem(ctx) return ast.U64
	preMember = null
	preStruct = null

	for i = 0 ; i < std.len(this.fields) ; i += 1 {
		expr = this.fields[i]
		islast = i == std.len(this.fields) - 1

		mustStruct = expr.tyassert == null

		if mustStruct && type(expr) == type(IndexExpr) {
			ie = expr
			if ie.varname == ""
				mustStruct = false
		}

		if preMember != null && mustStruct {
			this.check(preMember.isstruct,"field must be mem at chain expression in memgen")
		}


		curStruct = null
		curMember = null
		if type(expr) == type(StructMemberExpr) {
			curMember = expr.getMember()
			curStruct = curMember.parent
		}else if type(expr) == type(IndexExpr) {
			i = expr
			if i.varname == "" {
				i.check(preMember != null, "parent member is null")
				curMember = preMember.clone()
				if !curMember.isarr && curMember.pointer {
					curMember.pointer = false
				}
			}else {
				var = new VarExpr(i.varname,i.line,i.column)
				var.package = i.package
				
				realvar = var.getVar(ctx,i)
				this.check(realvar != null,"get var from indexexpr failed")
				
				if i.package == "" && realvar.stack && realvar.structname != "" {
					ele = package.getStruct(realvar.structpkg , realvar.structname)	
					this.check(ele.size > 0  , "check ele size")	
					
					curMember = new ast.Member()	
					curMember.structname = realvar.structname
					curMember.structpkg = realvar.structpkg
					curMember.isstruct = true
					curMember.pointer = false
					curMember.structref = ele	
					curStruct = curMember.parent
				}else {
					sm = new StructMemberExpr(i.package,this.line,this.column)
					sm.member = i.varname
					sm.var = realvar
					curMember = sm.getMember()
					curStruct = curMember.parent
					this.check(curMember != null," indexexpr get member failed")
				}
			}
		}else if type(expr) == type(FunCallExpr){
			ie = expr
			ie.check(ie.fcs != null,"static funcall not found fn signature")
			ti = ie.fcs.returnTypes[0]
			ie.check(ti.memType(),"should be static struct in chainexpr fncall")
			curStruct = ti.st
			curMember = null
			if islast
				return expr.getType(ctx)
		} else if type(expr) == type(MemberExpr){
			me = expr
			if preMember == null {
				if preStruct == null
					this.check(false,"preStruct is null")
				curMember = preStruct.getMember(me.membername)
				curStruct = curMember.parent
				this.check(curStruct == preStruct,"cur != pre")
			}else {
				if me.tyassert != null {
					curStruct = me.tyassert.getStruct()
				}else {
					preMember.initStructRef()
					this.check(
						preMember.structref != null , 
						"must be memref in chain expr"
					)
					curStruct = preMember.structref
				}
				curMember = curStruct.getMember(me.membername)
			}

			this.check(curMember != null,"memgen: mem not exist field2" + me.membername)
		}else if type(expr) == type(MemberCallExpr) {
			mc = expr
			st = null
			if mc.staticCall != null
				st = mc.staticCall
			else if mc.tyassert != null {
				st = mc.tyassert.getStruct() 
			}else {
				if preMember != null
					st = preMember.structref
				else 
					st = preStruct
			}
			mfc = st.getFunc(mc.membername)
			mc.check(mfc != null , "static funcall not signature")
			if std.len(mfc.returnTypes) > 0 {
				ti = mfc.returnTypes[0]
				if !islast
					mc.check(ti.memType(),"should be static struct in chainexpr fncall")
				if ti.memType(){
					curStruct = ti.st
					curMember = null
				}else if islast
					return ti.base
			}else {
				curStruct = null
				curMember = null
			}
		}else{
			this.check(false,"unsuport first type in chain")
		}
		preStruct = curStruct
		preMember = curMember
	}

	if preMember == null
		return ast.U64
		
	if preMember.pointer return ast.U64
	if preMember.type >= ast.I8 && preMember.type <= ast.F64{
		return preMember.type
	}
	return ast.U64
}
