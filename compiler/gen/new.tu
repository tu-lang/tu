use ast 
use compile
use internal
use parser
use parser.package
use std
use utils

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
	 fullpackage = compile.currentParser.import[this.package]
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
 