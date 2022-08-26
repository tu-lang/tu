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
    args      = [] # [Ast]
	childcall = false
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

	s = this.getReal()
	if s.father != null {
		father = new NewClassExpr(this.line,this.column)
		father.childcall = true
		father.package = s.father.pkg
		father.name = s.father.name
		// gen father
		father.compile(ctx)
		compile.Push()

		internal.newinherit_object(s.type_id)
		compile.Push()
	}else{
		internal.newobject(ast.Object,s.type_id)
		compile.Push()
	}

	
	for(fc : s.funcs){
		funcname = fc.parser.getpkgname() +
							"_" + s.name + "_" + fc.name

		compile.writeln("    mov %s@GOTPCREL(%%rip), %%rax", funcname)
		compile.Push()
		internal.object_func_add(fc.name)
	}
	//init called auto
	if !this.childcall {
		call = new FunCallExpr(this.line,this.column)
		call.package = s.parser.getpkgname()
		call.funcname = s.name + "init"
		call.is_pkgcall = true
		params = this.args
		pos = new ArgsPosExpr(1,this.line,this.column)
		call.args[] = pos
		std.merge(call.args,params)
		call.compile(ctx)
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
	call      # funcallexpr
	func init(line,column){
		super.init(line,column)
	}
}
MemberCallExpr::toString() {
    str = "MemberCallExpr(varname="
    str += this.varname
    str += ",func="
    str += this.membername
    str += ",args=" + this.call.toString()
    return str
}
MemberCallExpr::compile(ctx)
{
	this.record()
	utils.debug("membercall : ")
    if this.varname != "" {
        this.panic("varname should be null")
    }
    compile.Push()
    internal.object_member_get(this.membername)
    compile.Push()
	params = this.call.args
    
	pos = new ArgsPosExpr(this.line,this.column)
    //push obj
    //push obj.func
    //push $arg6
    //push $arg5
    //push $arg4
    //push $arg3
    //push $arg2
    pos.pos = 0
	call = this.call
	call.args = [pos]
	std.merge(call.args , params)
    call.compile(ctx)
    compile.writeln("    add $8, %%rsp")
	return null
}

