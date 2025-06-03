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
ChainExpr::getType(ctx){
	if !this.ismem(ctx) return ast.U8

	member    = null
	preStruct = null
	if type(this.first) == type(StructMemberExpr) {
		member = this.first.getMember()
		preStruct = member.parent
	}else if type(this.first) == type(IndexExpr) {
		i = this.first
		var = new VarExpr(i.varname,i.line,i.column)
        	var.package = i.package
		
		realvar = var.getVar(ctx,i)
		this.check(realvar != null,"get var from indexexpr failed")
		
		if i.package == "" && realvar.stack && realvar.structname != "" {
			ele = package.getStruct(realvar.structpkg , realvar.structname)	
			this.check(ele.size > 0  , "check ele size")	
			
			member = new ast.Member()	
			member.structname = realvar.structname
			member.structpkg = realvar.structpkg
			member.isstruct = true
			member.pointer = false
			member.structref = ele	
		}else {
			sm = new StructMemberExpr(i.package,this.line,this.column)
			sm.member = i.varname
			sm.var = realvar
			member = sm.getMember()
			this.check(member != null," indexexpr get member failed")
		}
	}

	for(j = 0 ; j < std.len(this.fields) ; j += 1){
		i = this.fields[j]
		this.check(type(i) == type(MemberExpr),"field must be member expression at mem chain expression")
		me = i
		if me.tyassert != null {
			member.isstruct = true
			member.structref = me.tyassert.getStruct()
		}
		this.check(member.isstruct,"must be memtype in chain expr")
		this.check(member.structref != null,"must be memref in chain expr")
		
		s = member.structref # Struct
		member = s.getMember(me.membername)
		this.check(member != null,"mem not exist field:" + me.membername)

		if j != (std.len(this.fields) - 1) {
			this.check(member.isstruct,"middle field must be mem type in chain expression:" + me.membername)
		}else{
			if !member.pointer && !member.isarr && member.structref == null {
				this.check(false,"last second field should be pointer in array index")
			}
		}
		// this.check(member.isstruct,"chainexpr::getType middle field must be mem type in chain expression field:" + me.membername)
	}
		
	this.check(this.last != null,"miss last field in chain expression")
	if type(this.last) == type(MemberCallExpr) {
		return ast.U64
	}
	if type(this.last) == type(IndexExpr) {
		return member.type
	}
	me = this.last
	if me.tyassert != null {
		member.isstruct = true
		member.structref = me.tyassert.getStruct()
	}
	this.check(member != null,"member is not exist in chainexpr")
	// this.check(member.structref != null,"must be memref in chain expr")
	if member.structref != null {
		ss = member.structref
		member = ss.getMember(me.membername)
	}
	this.check(member != null,"mem not exist field:" + me.membername)
	if member.pointer return ast.U64
	if member.type >= ast.I8 && member.type <= ast.F64{
		return member.type
	}
	return ast.U64
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
	if type(this.expr) == type(VarExpr) 
	{
		var = this.expr
		var = var.getVar(ctx,this)
		if var.pointer 
			return ast.U64
		
		else if var.structtype
			return var.type
		else 
			return ast.I64

	}else if type(this.expr) == type(StructMemberExpr) {
		e = this.expr
		m = e.getMember()
		if m.pointer return ast.U64
		return m.type
	}
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
	return var.getType(ctx)
}
MemberCallExpr::getType(ctx){
	this.panic("getType: unsupport MemberCall\n")
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
