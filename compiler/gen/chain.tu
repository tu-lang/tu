use ast
use parser
use parser.package
use compile
use std
use utils

class ChainExpr   : ast.Ast {
    first
    last
    fields = [] # array[Ast] 
    ret
	func init(line,column){
		super.init(line,column)
	}
}
ChainExpr::toString() {
    str = "ChainExpr("
    str += "left=" + this.first.toString()
    for(i : this.fields){
        str += "." + i.toString()
    }
    str += ",right=" + this.last.toString()
    str += ")"
    return str
}
ChainExpr::ismem(ctx) {
	if(type(this.first) == type(StructMemberExpr)) return true
	if(type(this.first) == type(IndexExpr)) {
		return exprIsMtype(this.first,ctx)
	}
	if type(this.first) == type(VarExpr) {
		varexpr = this.first
		realVar = varexpr.getVar(ctx,this)
		if realVar && !realVar.is_local && realVar.structtype {
			mexpr = new StructMemberExpr(realVar.varname,this.first.line,this.first.column)
            mexpr.var = realVar
            mexpr.member = varexpr.varname
			this.first = mexpr
			return true
		 }
	 }	
	 if type(this.first) == type(MemberExpr) {
		me = this.first
		return me.ismem(ctx)
	 }
	 return false
}
ChainExpr::compile(ctx)
{
	utils.debug("gen.ChainExpr::compile() ")
	this.record()
    if type(this.first) == type(StructMemberExpr) return this.memgen(ctx)
	if(type(this.first) == type(IndexExpr)){
		if(exprIsMtype(this.first,ctx)) 
			return this.memgen(ctx)
	}

	if type(this.first) == type(VarExpr) {
		varexpr = this.first
		realVar = varexpr.getVar(ctx,this)
		if (varexpr.getVarType(ctx,this) == ast.Var_Global_Extern_Static){
		   if std.len(this.fields) > 0 {
			   mexpr = new StructMemberExpr(realVar.varname,this.first.line,this.first.column)
			   mexpr.var = realVar
			   mexpr.member = this.fields[0].membername
			   std.pop_head(this.fields)
			   this.first = mexpr
			   return this.memgen(ctx)
		   }else{
			   if(type(this.last) == type(MemberCallExpr)){
				   fc = new FunCallExpr(realVar.line,realVar.column)
				   realVar.compile(ctx)
				   s = package.getStruct(realVar.package,realVar.structname)
				   return this.last.static_compile(ctx,s)
			   }else{
				   mexpr = new StructMemberExpr(realVar.varname,this.first.line,this.first.column)
				   mexpr.var = realVar
				   mexpr.member = this.last.membername
				   return mexpr.compile(ctx)
			   }
		   }
		}

		if realVar && !realVar.is_local && realVar.structtype {
			mexpr = new StructMemberExpr(realVar.varname,this.first.line,this.first.column)
			mexpr.var = realVar
			mexpr.member = varexpr.varname
			this.first = mexpr
			return this.memgen(ctx)
		}
	}else if type(this.first) == type(MemberExpr) {
		me = this.first
		if me.ismem(ctx) {
			mexpr = new StructMemberExpr(me.varname,this.line,this.column)
			mexpr.var = me.ret
			if me.tyassert != null {
				v = me.ret.clone()
				v.structpkg  = me.tyassert.pkgname
				v.structname = me.tyassert.name
				mexpr.var = v
			}
			mexpr.member = me.membername
			this.first = mexpr
			return this.memgen(ctx)
		}
	}	

	return this.objgen(ctx)
}

ChainExpr::memgen(ctx)
{
	utils.debug("gen.ChainExpr::memgen()")
	if(type(this.last) == type(IndexExpr)){
		return this.indexgen(ctx)
	}
	member = null
	if(type(this.first) == type(StructMemberExpr)){
		this.first.compile(ctx)
		s = this.first
		member = s.getMember()
	}else if(type(this.first) == type(IndexExpr)){
		ie = this.first
		ie.compile_static(ctx)
		member = ie.ret
	}else{
		this.check("unsuport first type in chain")
	}
	need_check = true
	lastn = this.last
	if type(this.last) == type(MemberCallExpr) {
		if lastn.tyassert != null
			need_check = false
	}else if type(this.last) == type(MemberExpr) {
		if lastn.tyassert != null
			need_check = false
	}
	if need_check
		this.check(member.isstruct,"field must be mem at chain expression in memgen")
	if (member.pointer || !need_check ) && !member.isarr{
		if type(this.first) != type(IndexExpr)
			compile.Load()
	}
	for i : this.fields {
		this.check(type(i) == type(MemberExpr),"field must be member expression at mem chain expression")
		me = i
		this.check(member.structref != null,"must be memref in chain expr")
		s = member.structref
		member = s.getMember(me.membername)
		this.check(member != null,"mem not exist field:" + me.membername)
		this.check(member.isstruct,"middle field must be mem type in chain expression")

		compile.writeln("	add $%d, %%rax",member.offset)
		if member.pointer {
			compile.Load()
		}
	}
	this.check(this.last != null,"miss last field in chain expression")

	if type(this.last) == type(MemberExpr) {
		me = this.last
		ss = null
		if me.tyassert != null {
			ss = me.tyassert.getStruct()
		}else{
			this.check(member.structref != null,"must be memref in chain expr")
			ss = member.structref
		}
		member = ss.getMember(me.membername)
		this.check(member != null,"mem not exist field:" + me.membername)
		compile.writeln("	add $%d, %%rax",member.offset)
	}else if type(this.last) == type(MemberCallExpr) {
		lastn = this.last
		if lastn.tyassert != null
			lastn.static_compile(ctx,lastn.tyassert.getStruct())
		else 
			lastn.static_compile(ctx,member.structref)
	}else{
		this.panic("chain invalid")
	}		
	this.ret = member
	return this
}

ChainExpr::objgen(ctx)
{
	utils.debug("gen.ChainExpr::objgen()")
	this.record()
	ret = this.first.compile(ctx)
	if ret != null && type(ret) == type(StructMemberExpr) {
		compile.LoadMember(ret.ret)
	}
	compile.Push()

	for(i : this.fields){
		i.compile(ctx)
		compile.Push()
	}
	this.last.compile(ctx)
    return null
}

ChainExpr::assign(ctx , opt, rhs) {
	utils.debug("gen.ChainExpr::assign()")
	this.record()
    this.first.compile(ctx)
    compile.Push()
	for i : this.fields {
		i.compile(ctx)
		compile.Push()
	}
	if  type(this.last) == type(MemberExpr) {
		me  = this.last
        rhs.compile(ctx)
        compile.Push()
        internal.call_object_operator(opt,me.membername,"runtime_object_unary_operator")
	}else if type(this.last) == type(IndexExpr) {
		this.last.assign(ctx,opt,rhs)
	}else{
		this.panic(this.toString(""))
	}
	return null
}