use ast 
use compile
use internal
use parser
use parser.package
use std
use utils

class NewExpr : ast.Ast {
    package name
    len
	func init(line,column){
		super.init(line,column)
	}
}
NewExpr::toString(){
    str = "NewExpr("
    str += this.package
    str += ","
    str += this.name
    str += ")"
    return str
}

NewExpr::compile(ctx)
{
	this.record()
	//1. new 100
	if this.package == "" && this.name == "" {
		internal.gc_malloc(this.len)
		 return this
	 }
	 fullpackage = compile.parser.import[this.package]
	 if std.exist(fullpackage,package.packages)  {
		s = null
		if s = package.packages[fullpackage].getStruct(this.name) && s != null {
			internal.gc_malloc(s.size)
			return this
		}else{
			var = new VarExpr(this.name,0,0)
			var.package = this.package
			if !var.isMemtype(ctx) {
				this.panic("AsmError: var must be memtype in (new var)")
			}
			real_var = var.getVar(ctx)
			real_var.compile(ctx)
			internal.gc_malloc()
			return this
		}
	 }
	 this.panic(
		"asmgen: New(%s.%s) not right maybe package(%s) not import? line:%d column:%d",
	 	this.package,this.name,this.package,this.line,this.column
	)
	 compile.writeln("   mov $0,%%rax")
	 return this
 }
 
class NewClassExpr : ast.Ast {
    package name
    args = [] # [Ast]
	func init(line,column){
		super.init(line,column)
	}
}
NewClassExpr::toString(){
    str = "NewExpr("
    str += this.package
    str += ","
    str += this.name
    str += ")"
    return str
}

NewClassExpr::compile(ctx)
{
	this.record()
	utils.debug("new expr got: type:%s",this.name)
	s = null
	if this.package != "" {
		realPkg = compile.parser.import[this.package]
		pkg = package.packages[realPkg]
		if pkg != null {
			s = pkg.getClass(this.name)
		}
	}else{
		s = compile.parser.pkg.getClass(this.name)
	}
	if !s {
		this.panic("AsmError: class is not define of " + this.name)
	}
	internal.newobject(ast.Object,std.len(s.funcs))
	compile.Push()
	
	exist_init = false
	for(fc : s.funcs){
		if fc.name == "init"  exist_init = true

		funcname = fc.parser.getpkgname() +
							"_" + s.name + "_" + fc.name

		compile.writeln("    mov %s@GOTPCREL(%%rip), %%rax", funcname)
		compile.Push()
		internal.object_func_add(fc.name)
	}
	if !exist_init {
		funcname = s.pkg + "_" + s.name + "_init"
		compile.writeln("    mov %s@GOTPCREL(%%rip), %%rax", funcname)
		compile.Push()
		internal.object_func_add("init")
	}
	compile.Pop("%rax")

	return null
}

class MemberExpr : Ast {
    varname  membername
	func init(line,column){
		super.init(line,column)
	}
}
MemberExpr::toString(){
    str = "MemberExpr("
    str += this.varname
    str += "."
    str += this.membername
    str += ")"
    return str
}


MemberExpr::compile(ctx)
{
	this.record()
	if this.varname == "" {
		internal.object_member_get(this.membername)
		return null
	}
	var = ast.getVar(ctx,this.varname)
	compile.GenAddr(var)
	compile.Load()
	compile.Push()
	internal.object_member_get(this.membername)
	return null
}

class MemberCallExpr : ast.Ast {
    varname membername
    args = [] # [Ast]
	func init(line,column){
		super.init(line,column)
	}
}
MemberCallExpr::toString() {
    str = "MemberCallExpr(varname="
    str += this.varname
    str += ",func="
    str += this.membername
    str += ",args=["
    for (arg : this.args) {
        str += arg.toString()
        str += ","
    }
    str += "])"
    return str
}
MemberCallExpr::compile(ctx)
{
	this.record()
	utils.debug("membercall : ")
	return null
}

