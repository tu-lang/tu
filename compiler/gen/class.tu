use ast 
use compile
use internal
use parser
use parser.package
use std
use utils

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
NewClassExpr::getReal(){
	s = null
    if(this.package != ""){
		realPkg = GP().import[this.package]
		pkg = package.packages[realPkg]
        if(pkg){
            s = pkg.getClass(this.name)
        }
    }else{
        s = GP().pkg.getClass(this.name)
    }
    if(!s){
        this.check(false,"AsmError: class is not define of " + this.name)
    }
    return s
}

NewClassExpr::compile(ctx)
{
	utils.debug("gen.NewClassExpr::compile()")
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
		call.funcname = "init"
		call.cls     = s
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

class MemberExpr : ast.Ast {
    varname  membername

	ret //var*
	tyassert
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
	utils.debug("gen.MemberExpr::compile()")
	this.record()
	if this.varname == "" {
		internal.object_member_get(this,this.membername)
		return null
	}
	var = GP().getGlobalVar("",this.varname)
	if var == null
		var = ast.getVar(ctx,this.varname)
	this.check(var != null,this.toString(""))
	if var.structtype {
		mexpr = new StructMemberExpr(this.varname,this.line,this.column)
		mexpr.var = var
		mexpr.member = this.membername
		return mexpr.compile(ctx)
	}else if this.tyassert != null { 
		mexpr = new StructMemberExpr(this.varname,this.line,this.column)
        vv = var.clone()
        vv.structpkg = this.tyassert.pkgname
        vv.structname = this.tyassert.name
        mexpr.var = vv
        mexpr.member = this.membername
        return mexpr.compile(ctx)
	}
	compile.GenAddr(var)
	compile.Load()
	compile.Push()
	internal.object_member_get(this,this.membername)
	return var
}
MemberExpr::assign(ctx, opt ,rhs)
{
	utils.debug("gen.MemberExpr::assign()")
    this.record()
    if this.ismem(ctx) {
		mexpr = new StructMemberExpr(this.varname,this.line,this.column)
        mexpr.var = this.ret
        if this.tyassert != null {
			v = this.ret.clone()
            v.structpkg  = this.tyassert.pkgname
            v.structname = this.tyassert.name
            mexpr.var = v
        }
        mexpr.member = this.membername
		oh = new OperatorHelper(ctx,mexpr,rhs,opt)
        return oh.gen()
    }

	var = GP().getGlobalVar("",this.varname)
    if var == null 
        var = ast.getVar(ctx,this.varname)
    this.check(var != null,this.toString(""))

    compile.GenAddr(var)
    compile.Load()
    compile.Push()

    rhs.compile(ctx)
    compile.Push()
    internal.call_object_operator(opt,this.membername,"runtime_object_unary_operator")
    return null
}

class MemberCallExpr : ast.Ast {
    varname membername

	tyassert
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
MemberCallExpr::static_compile(ctx,s){
    this.record()
    compile.Push()
	p = s.parser
	cls = package.packages[p.getpkgname()].getClass(s.name)
    fn = cls.getFunc(this.membername)
    if fn == null this.check(false,"func not exist:" + this.membername)
    compile.writeln("    mov %s@GOTPCREL(%%rip), %%rax", fn.fullname())
    compile.Push()
	call = this.call
	params = call.args
	pos = new ArgsPosExpr(this.line,this.column)
    pos.pos = 0
    call.args = []
    call.args[] = pos
	std.merge(call.args,params)
    call.compile(ctx)
    compile.writeln("    add $8, %%rsp")
    return null
}
MemberCallExpr::compile(ctx)
{
	this.record()
	utils.debug("gen.MemberCallExpr::compile")
    if this.varname != "" {
        this.panic("varname should be null")
    }
    if this.tyassert != null {
        compile.Pop("%rax")
        s = this.tyassert.getStruct()
        return this.static_compile(ctx,s)
    }
    compile.Push()
    internal.object_member_get(this,this.membername)
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

MemberExpr::ismem(ctx){
	var = GP().getGlobalVar("",this.varname)
    if var == null
        var = ast.getVar(ctx,this.varname)
    this.check(var != null,this.toString(""))
    this.ret = var
    if this.tyassert != null return true
    if var.structtype {
        return true
    } 
    return false
}

MemberExpr::getMember(ctx){
    if !this.ismem(ctx) return null

	mexpr = new StructMemberExpr(this.varname,this.line,this.column)
    mexpr.var = this.ret
    mexpr.member = this.membername
    return mexpr.getMember()
}