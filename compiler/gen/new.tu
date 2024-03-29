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
 