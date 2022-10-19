use ast
use compile
use std

class StructMemberExpr : ast.Ast {
    varname = varname
    member
    var
    assign
    ret
	func init(varname,line,column){
		super.init(line,column)
	}
}
StructMemberExpr::toString() {
	return fmt.sprintf(
		"StructMemberExpr(%s<%s.%s>.%s)" ,
		this.varname , this.var.package , 
		this.var.structname , this.member
	)
}
StructMemberExpr::getMember()
{
	s = this.getStruct()
	if s == null return False

	m = s.getMember(this.member)
	if m == null {
        this.panic("mem.member: mem:%s member:%s not exist"
			s.name,this.member
		)
	}
	return m
}
StructMemberExpr::getStruct()
{
	package = this.var.structpkg
	if (package == "" ){
		package = this.var.package
	}
	s = null
	
	if GP().import.count(package) {
		package = GP().import[package]
	}
	if std.len(package.packages,package < 1){
		this.panic("mem package not exist:%s" ,package)
	}
	s = package.packages[package].getStruct(this.var.structname)
	if s == null {
        this.panic("mem type not exist :%s" , this.var.structname)
	}
	return s
}

StructMemberExpr::compile(ctx)
{
	this.record()
	filename = compile.currentParser.filename
	
	m = this.getMember()
	if m == null {
        this.panic("struct.member: class member:%s not exist  file:%s\n",
			this.member,filename
		)
	}
	compile.GenAddr(this.var)
	compile.Load()
	compile.writeln("	add $%d, %%rax", m.offset)
	
	this.ret = m
	return this
}

