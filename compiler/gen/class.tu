use ast 
use compile
use internal
use parser
use std
use utils

ast.NewExpr::compile(ctx)
{
	record()
	//1. new 100
	if package == "" && name == "" {
		internal.gc_malloc(len)
		 return this
	 }
	 package = compile.parser.import[this.package]
	 if std.exist(packge,parser.packages)  {
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
	 compile.writeln("   mov $0,%%rax")
	 return this
 }
 

ast.NewClassExpr::compile(ctx)
 {
	record()
	utils.debug("new expr got: type:%s",this.name)
	s = null
	if this.package != "" {
		realPkg = compile.parser.import[package]
		pkg = parser.packages[realPkg]
		if pkg != null {
			s = pkg.getClass(this.name)
		}
	}else{
		s = compile.parser.pkg.getClass(this.name)
	}
	if !s {
		this.panic("AsmError: class is not define of " + name)
	}
	internal.newobject(Object,s.funcs.size())
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
ast.MemberExpr::compile(ctx)
{
	record()
	if this.varname == "" {
		internal.object_member_get(membername)
		return null
	}
	var = ast.getVar(ctx,varname)
	compile.GenAddr(var)
	compile.Load()
	compile.Push()
	internal.object_member_get(membername)
	return null
}
ast.MemberCallExpr::compile(ctx)
{
	record()
	utils.debug("membercall : ")
	return null
}

