use ast
use compile
use std
use parser.package


class StructInitExpr : ast.Ast {
	func init(line,column){
		super.init(line,column)
	}
	pkgname = ""
	name    = ""

	fields = {} // fieldname : expression
}
StructInitExpr::toString(s){
	return fmt.sprintf("struct init(%s.%s)"
		this.pkgname,this.name
	)
}
class NewStructExpr : ast.Ast {
	func init(line,column){
		super.init(line,column)
	}
	init //struct init expr
}
NewStructExpr::toString(s){
	return fmt.sprintf(
		"new (%s)",
		this.init.toString(s)
	)
}

class StructMemberExpr : ast.Ast {
    varname = varname
    member  = ""
    var
    assign
    ret

	tyassert
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
		this.check(false,"mem.member: mem:" + s.name + " member:" + this.member + " not exist")
	}
	return m.clone()
}
StructMemberExpr::getStruct()
{
	packagename = this.var.structpkg
	sname = this.var.structname
    utils.debugf("gen.StructMemberExpr::getStruct() pkgname:%s name:%s\n",packagename,sname)
	if this.tyassert != null {
		packagename = this.tyassert.pkgname
		sname  = this.tyassert.name
	}	
	if packagename == "" {
		packagename = this.var.package
	}
	s = null
	
	if GP().import[packagename] != null {
		packagename = GP().import[packagename]
	}
	if package.packages[packagename] == null {
		this.check(false,"mem package not exist:%s" ,packagename)
	}
	s = package.packages[packagename].getStruct(sname)
	if s == null {
        this.check(false,"mem type not exist :%s" , sname)
	}
	return s
}

StructMemberExpr::compile(ctx)
{
    utils.debugf("gen.StructMemberExpr::compile()")
	this.record()
	filename = compile.currentParser.filename

	if(this.var == null){
		this.var = ast.getVar(ctx,this.varname)
	}
	if(this.var == null){
		this.var = GP().getGlobalVar(this.varname,this.member)
	}
	if(this.var == null){
		this.check(false,"this.var is null")
	}

	
	m = this.getMember()
	if m == null {
        this.panic("struct.member: class member:%s not exist  file:%s\n",
			this.member,filename
		)
	}
	compile.GenAddr(this.var)
	if(!this.var.stack)
		compile.Load()
	compile.writeln("	add $%d, %%rax", m.offset)
	
	this.ret = m
	return this
}

