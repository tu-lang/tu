ast.StructMemberExpr::getMember()
{
	s = getStruct()
	if s == null return null

	m = s.getMember(this.member)
	if m == null {
        panic("mem.member: mem:" + s.name + " member:" + this.member + " not exist")
	}
	return m
}
ast.StructMemberExpr::getStruct()
{
	package = var.package
	s = null
	
	package = compile.parser.import[package]
	if std.len(package.packages,package < 1){
		check(false,"mem package not exist:" + package)
	}
	s = package.packages[package].getStruct(var.structname)
	if s == null{
        check(false,"mem type not exist :" + var.structname)
	}
	return s
}

ast.StructMemberExpr::compile(ctx)
{
	record()
	filename = compile.parser.filename
	
	m = getMember()
	if m == null{
        parse_err("struct.member: class member:%s not exist  file:%s\n",this.member,filename)
	}
	compile.GenAddr(this.var)
	compile.Load()
	compile.writeln("	add $%d, %%rax", m.offset)
	
	this.ret = m
	return this
}

