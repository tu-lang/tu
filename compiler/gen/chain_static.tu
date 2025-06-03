use compiler.ast
use compiler.parser
use compiler.compile
use std
use compiler.utils


ChainExpr::indexgen(ctx,load)
{
	utils.debugf("gen.ChainExpr::indexgen()")
	member = null
	if(type(this.first) == type(StructMemberExpr)){
		this.first.compile(ctx,false)
		s = this.first
		member = s.getMember()
	}else if(type(this.first) == type(IndexExpr)){
		ie = this.first
		ie.compile_static(ctx)
		member = ie.ret
	}else{
		this.check(false,"unsuport first type in chain in indexgen")
	}
	if(!member.isarr)
		this.check(member.pointer || member.isstruct,"field " + member.name + " must be mem at chain expression in indexgen")
	if(member.pointer && !member.isarr){
		compile.Load()
	}
	for(i = 0 ; i < std.len(this.fields) ; i += 1 ){
		field = this.fields[i]
		this.check(type(field) == type(MemberExpr),"field must be member expression at mem chain expression")
		me = field
		this.check(member.structref != null,"must be memref in chain expr")
		s = member.structref
		member = s.getMember(me.membername)
		this.check(member != null,"mem not exist field:" + me.membername)
		if i != std.len(this.fields) - 1 {
			this.check(member.isstruct,"middle field must be mem type in chain expression")
		}else{
			if !member.pointer && !member.isarr {
				this.check(false,"last second field should be pointer in array index")
			}
		}
		compile.writeln("	add $%d, %%rax",member.offset)
		if member.pointer {
			compile.Load()
		}
	}
	this.check(this.last != null,"miss last field in chain expression")
	if type(this.last) != type(IndexExpr) {
		this.check(false,"last field should be index")
	}

	index = this.last
	index.compile_chain_static(ctx,member.size)

	if load {
		compile.LoadSize(member.size,member.isunsigned)
	}

	ret = new StructMemberExpr("",this.line,this.column)
	ret.s = member.structref
	ret.m = member
	return ret
}