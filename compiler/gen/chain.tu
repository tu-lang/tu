use ast
use parser
use compile
use std

ChainExpr::ismem(ctx) {
	//TODO: support type keyword
	if type(first) == type(ast.VarExpr) {
		varexpr = first
		realVar = varexpr.getVar(ctx)
		if realVar && !realVar.is_local && realVar.structtype {
			mexpr = new ast.StructMemberExpr(realVar.varname,first.line,first.column)
            mexpr.var = realVar
            mexpr.member = varexpr.varname
			this.first = mexpr
			return true
		 }
	 }	
	 return false
}
ChainExpr::compile(ctx)
{
	record()
    if type(first) == type(ast.StructMemberExpr) return this.memgen(ctx)

	 if type(first) == type(ast.VarExpr)){
		varexpr = first
		realVar = varexpr.getVar(ctx)
		if realVar && !realVar.is_local && realVar.structtype {
			mexpr = new StructMemberExpr(realVar.varname,first.line,first.column)
            mexpr.var = realVar
            mexpr.member = varexpr.varname
			this.first = mexpr
			return this.memgen(ctx)
		 }
	 }
	return this.objgen(ctx)
}

ChainExpr::memgen(ctx)
{
	this.first.compile(ctx)
	s = this.first
	member = s.getMember()
	this.check(member.isstruct,"field must be mem at chain expression")
	if member.pointer {
		this.obj.Load()
	}
	for (i : fields) {
		this.check(type(*i) == type(MemberExpr),"field must be member expression at mem chain expression")
		me = i
		this.check(member.structref != null,"must be memref in chain expr")
		s = member.structref
		member = s.getMember(me.membername)
		this.check(member != null,"mem not exist field:" + me.membername)
		this.check(member.isstruct,"middle field must be mem type in chain expression")

		this.obj.writeln("	add $%d, %rax",member.offset)
		if member.pointer {
			this.obj.Load()
		}
	}
	//遍历最后一个节点，如果没有那肯定parser出错了
	check(last != null,"miss last field in chain expression")
	me = last
	check(member.structref != null,"must be memref in chain expr")
	ss = member.structref
	member = ss.getMember(me.membername)
	check(member != null,"mem not exist field:" + me.membername)
	this.obj.writeln("	add $%d, %rax",member.offset)
	this.ret = member
	return this
}

ChainExpr::objgen(ctx)
{
	record()
    this.first.compile(ctx)
	this.obj.Push()

	for(i : this.fields){
		i.compile(ctx)
		this.obj.Push()
	}
	this.last.compile(ctx)
    return null
}