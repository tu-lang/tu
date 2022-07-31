BoolExpr::getType(ctx){
	return ast.U8
}
CharExpr::getType(ctx){
	return ast.I8
}
NullExpr::getType(ctx){
	return ast.U8
}
IntExpr::getType(ctx){
	return ast.I64
}
DoubleExpr::getType(ctx){
	panic("getType: unsupport double\n")
}
StringExpr::getType(ctx){
	return ast.U64
}
ArrayExpr::getType(ctx){
	panic("getType: unsupport array\n")
}
MapExpr::getType(ctx){
	panic("getType: unsupport map\n")
}
KVExpr::getType(ctx){
	panic("getType: unsupport kv\n")
}
ChainExpr::getType(ctx){
	check(ismem(ctx),"gettype: unsuport chain")

	s 	= this.first
	member = s.getMember()
	
	check(member.isstruct,"must be memtype in chain expr")
	for(i : fields){
		check(type(i) == type(MemberExpr),"field must be member expression at mem chain expression")
		me = i
		check(member.structref != null,"must be memref in chain expr")
		
		s = (Struct*)(member.structref)
		member = s.getMember(me.membername)
		check(member != null,"mem not exist field:" + me.membername)
		
		check(member.isstruct,"middle field must be mem type in chain expression")
	}
		
	check(last != null,"miss last field in chain expression")
	me = last
	check(member.structref != null,"must be memref in chain expr")
	ss = member.structref
	member = ss.getMember(me.membername)
	check(member != null,"mem not exist field:" + me.membername)
	if member.pointer return ast.U64
	if member.type >= ast.I8 && member.type <= ast.U64{
		return member.type
	}
	return ast.U64
}
VarExpr::getType(ctx){
	getVarType(ctx)
	if ret.pointer return ast.U64

	return ret.type
}
ClosureExpr::getType(ctx){
	panic("getType: unsupport closure\n")
}
StructMemberExpr::getType(ctx){
	m = getMember()
	if m.pointer || m.isclass return ast.U64
	return m.type
}
AddrExpr::getType(ctx){
	return ast.U64
}
DelRefExpr::getType(ctx){
	if type(expr) == type(VarExpr) {
		var = expr
		var = var.getVar(ctx)
		if var.pointer 
			return ast.U64
		
		else if var.structtype
			return var.type
		else 
			return ast.I64

	}else if type(expr) == type(ast.StructMemberExpr) {
		e = expr
		m = e.getMember()
		if m.pointer return ast.U64
		return m.type
	}
	return expr.getType(ctx)
}
IndexExpr::getType(ctx){
	panic("getType: unsupport IndexExpr\n")
}
BinaryExpr::getType(ctx){
	
	if !this.rhs return lhs.getType(ctx)
	l = lhs.getType(ctx)
	r = rhs.getType(ctx)
	return max(l,r)
}
FunCallExpr::getType(ctx){
	return ast.U64
	
}
AssignExpr::getType(ctx){
	panic("getType: unsupport Assign\n")
}
NewClassExpr::getType(ctx){
	panic("getType: unsupport new class\n")
}
BuiltinFuncExpr::getType(ctx){
	return ast.U64
	panic("getType: unsupport builtin\n")
}
NewExpr::getType(ctx){
	return ast.U64
	
}
MemberExpr::getType(ctx){
	panic("getType: unsupport Member\n")
}
MemberCallExpr::getType(ctx){
	panic("getType: unsupport MemberCall\n")
}
MatchCaseExpr::getType(ctx){
	panic("getType: unsupport MatchCaseExpr\n")
}
IfCaseExpr::getType(ctx){
	panic("getType: unsupport IfCaseExpr\n")
}
LabelExpr::getType(ctx){
	panic("getType: unsupport LabelExpr\n")
}