use compiler.ast
use compiler.compile
use std
use compiler.parser.package


class StructInitExpr : ast.Ast {
	func init(line,column){
		super.init(line,column)
	}
	pkgname = ""
	name    = ""

	fields = {} // fieldname : expression
}
StructInitExpr::toString(){
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
NewStructExpr::toString(){
	return fmt.sprintf(
		"new (%s)",
		this.init.toString()
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
	if s == null return false

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
	if packagename == "" || packagename == null{
		packagename = this.var.package
	}
	s = null
	pkg = GP().pkg.getPackage(packagename)	
	if pkg == null {
		fmt.println(packagename)
		for  k,v : package.packages {
			fmt.println(k)
		}
		this.check(false,"mem package not exist: " + packagename)
	}
	s = pkg.getStruct(sname)
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
		this.var = ctx.getOrNewVar(this.varname)
	}
	if(this.var == null){
		this.var = GP().getGlobalVar(this.varname,this.member)
	}
	if(this.var == null){
		this.check(false,"this.var is null")
	}

	
	m = this.getMember()
	if m == null {
        this.panic(
			fmt.sprintf(
				"struct.member: class member:%s not exist\n",
				this.member
			)
		)
	}
	compile.GenAddr(this.var)
	if(!this.var.stack)
		compile.Load()
	compile.writeln("	add $%d, %%rax", m.offset)
	
	this.ret = m
	return this
}

