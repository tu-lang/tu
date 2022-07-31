use ast 
use compile
use internal
use parser
use std
use utils

NewExpr::compile(ctx)
{
	record()
	//1. new 100
	if package == "" && name == "" {
		internal.gc_malloc(len)
		 return this
	 }
	 package = this.obj.parser.import[this.package]
	 if std.exist(parser.packages.count(package)) > 0 {
		s = null
		if s = parser.packages[package].getStruct(name) && s != null {
			internal.gc_malloc(s.size)
			return this
		}else{
			var = new VarExpr(name,0,0)
			var.package = package
			if !var.isMemtype(ctx) {
				this.panic("AsmError: var must be memtype in (new var)")
			}
			real_var = var.getVar(ctx)
			real_var.compile(ctx)
			internal.gc_malloc()
			return this
		}
	 }
	 parse_err("asmgen: New(%s.%s) not right maybe package(%s) not import? line:%d column:%d\n",this.package,this.name,this.package,line,column)
	 this.obj.writeln("   mov $0,%%rax")
	 return this
 }
 

NewClassExpr::compile(ctx)
 {
	record()
	utils.debug("new expr got: type:%s",this.name)
	s = null
	if this.package != "" {
		realPkg = this.obj.parser.import[package]
		pkg = parser.packages[realPkg]
		if pkg != null {
			s = pkg.getClass(this.name)
		}
	}else{
		s = this.obj.parser.pkg.getClass(this.name)
	}
	if !s {
		this.panic("AsmError: class is not define of " + name)
	}
	internal.newobject(Object,s.funcs.size())
	this.obj.Push()
	
	exist_init = false
	for(fc : s.funcs){
		if fc.name == "init"  exist_init = true

		funcname = fc.parser.getpkgname() +
							"_" + s.name + "_" + fc.name

		this.obj.writeln("    mov %s@GOTPCREL(%%rip), %%rax", funcname)
		this.obj.Push()
		internal.object_func_add(fc.name)
	}
	if !exist_init {
		funcname = s.pkg + "_" + s.name + "_init"
		this.obj.writeln("    mov %s@GOTPCREL(%%rip), %%rax", funcname)
		this.obj.Push()
		internal.object_func_add("init")
	}
	this.obj.Pop("%rax")

	return null
}
MemberExpr::compile(ctx)
{
	record()
	if this.varname == "" {
		internal.object_member_get(membername)
		return null
	}
	var = ast.getVar(ctx,varname)
	this.obj.GenAddr(var)
	this.obj.Load()
	this.obj.Push()
	internal.object_member_get(membername)
	return null
}
MemberCallExpr::compile(ctx)
{
	record()
	utils.debug("membercall : ")
	return null
}

