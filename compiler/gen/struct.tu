StructMemberExpr::getMember()
{
	s = getStruct()
	if s == null return null

	m = s.getMember(this.member)
	if m == null {
        panic("mem.member: mem:" + s.name + " member:" + this.member + " not exist")
	}
	return m
}
StructMemberExpr::getStruct()
{
	package = var.package
	s = null
	
	package = Compiler::parser.import[package]
	if std.len(Package::packages,package < 1){
		check(false,"mem package not exist:" + package)
	}
	s = Package::packages[package].getStruct(var.structname)
	if s == null{
        check(false,"mem type not exist :" + var.structname)
	}
	return s
}

StructMemberExpr::compile(ctx)
{
	record()
	filename = Compiler::parser.filename
	
	m = getMember()
	if m == null{
        parse_err("struct.member: class member:%s not exist  file:%s\n",this.member,filename)
	}
	Compiler::GenAddr(this.var)
	Compiler::Load()
	Compiler::writeln("	add $%d, %%rax", m.offset)
	
	this.ret = m
	return this
}

