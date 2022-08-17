use ast
use compile
use std

class StructMemberExpr : Ast {
    varname = varname
    member
    var
    assign
    ret
	func init(varname,line,column){
		super.init(line,column)
	}
}
StructMemberExpr::toString(){
    return "StructMemberExpr(" + varname + "<"+var.package+"."+var.structname+">"+"."+member+")"
}
StructMemberExpr::getMember()
{
	s = getStruct()
	if s == null return null

	m = s.getMember(this.member)
	if m == null {
        panic("mem.member: mem:%s member:%s not exist"
			s.name,this.member
		)
	}
	return m
}
StructMemberExpr::getStruct()
{
	package = var.structpkg
	s = null
	
	package = compile.parser.import[package]
	if std.len(package.packages,package < 1){
		panic("mem package not exist:%s" ,package)
	}
	s = package.packages[package].getStruct(var.structname)
	if s == null{
        panic("mem type not exist :%s" ,var.structname)
	}
	return s
}

StructMemberExpr::compile(ctx)
{
	record()
	filename = compile.parser.filename
	
	m = getMember()
	if m == null {
        panic("struct.member: class member:%s not exist  file:%s\n",
			this.member,filename
		)
	}
	compile.GenAddr(this.var)
	compile.Load()
	compile.writeln("	add $%d, %%rax", m.offset)
	
	this.ret = m
	return this
}

