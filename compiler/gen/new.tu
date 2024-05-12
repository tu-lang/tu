use compiler.ast 
use compiler.compile
use compiler.internal
use compiler.parser
use compiler.parser.package
use std
use compiler.utils

class NewExpr : ast.Ast {
    package = ""
	name    = ""
    len
	arrsize
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
	utils.debug("gen.NewExpr::compile()")
	this.record()
	//1. new 100
	if this.package == "" && this.name == "" {
		internal.gc_malloc(this.len)
		 return this
	 }
	 pkg = compile.currentParser.pkg.getPackage(this.package)
	 if pkg != null {
		s = null
		if (s = pkg.getStruct(this.name) ) && s != null {
			internal.gc_malloc(s.size)
			return this
		}else{
			var = new VarExpr(this.name,this.line,this.column)
			var.package = this.package
			if !var.isMemtype(ctx) {
				this.panic("AsmError: var must be memtype in (new var)")
			}
			real_var = var.getVar(ctx,this)
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
 
NewClassExpr::compile(ctx)
{
	utils.debug("gen.NewClassExpr::compile()")
	this.record()
	utils.debug("new expr got: type:%s",this.name)

	s = this.getReal()
	objsize = std.len(s.membervars) * 8

	parent = s.father
	while parent != null {
		parent = parent.getReal()
		objsize += std.len(parent.membervars) * 8
		parent = parent.father
	}

	fullpackage = GP().getImport(this.package)
	m = package.getStruct(fullpackage,this.name)
	if m != null {
		internal.gc_malloc(m.size)
	}else{
		internal.newclsobject(s.virtname(),objsize)
	}
	compile.Push()

	call = new FunCallExpr(this.line,this.column)
	call.package = s.parser.getpkgname()
	call.funcname = "init"
	call.cls     = s
	call.is_pkgcall = true
	params = this.args
	pos = new ArgsPosExpr(1,this.line,this.column)
	//find params count
	fc = s.getFunc("init")
	pos.pos = std.len(fc.params_order_var)  - 1

	call.args[] = pos
	std.merge(call.args,params)
	call.compile(ctx)

	compile.Pop("%rax")

	return null
}
