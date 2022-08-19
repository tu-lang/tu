use ast
use parser
use compile
use std

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
	//TODO: support type keyword
	if type(this.first) == type(VarExpr) {
		varexpr = this.first
		realVar = varexpr.getVar(ctx)
		if realVar && !realVar.is_local && realVar.structtype {
			mexpr = new StructMemberExpr(realVar.varname,this.first.line,this.first.column)
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
	this.record()
    if type(this.first) == type(StructMemberExpr) return this.memgen(ctx)

	 if type(this.first) == type(VarExpr) {
		varexpr = this.first
		realVar = varexpr.getVar(ctx)
		if realVar && !realVar.is_local && realVar.structtype {
			mexpr = new StructMemberExpr(realVar.varname,this.first.line,this.first.column)
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

		compile.writeln("	add $%d, %rax",member.offset)
		if member.pointer {
			compile.Load()
		}
	}
	//遍历最后一个节点，如果没有那肯定parser出错了
	this.check(this.last != null,"miss last field in chain expression")
	me = this.last
	this.check(member.structref != null,"must be memref in chain expr")
	ss = member.structref
	member = ss.getMember(me.membername)
	this.check(member != null,"mem not exist field:" + me.membername)
	compile.writeln("	add $%d, %rax",member.offset)
	this.ret = member
	return this
}

ChainExpr::objgen(ctx)
{
	this.record()
    this.first.compile(ctx)
	compile.Push()

	for(i : this.fields){
		i.compile(ctx)
		compile.Push()
	}
	this.last.compile(ctx)
    return null
}