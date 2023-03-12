use ast
use compile
use std
use fmt
use parser.package

class TypeAssertExpr : ast.Ast {
	func init(line,column){
		super.init(line,column)
	}
	pkgname = ""
	name    = ""
}
TypeAssertExpr::toString() { 
	return fmt.sprintf("TypeAssertExpr(%s.%s)"
		this.pkgname,this.name
	)
}

TypeAssertExpr::compile(ctx){
    return null

}
TypeAssertExpr::getStruct(){
	name = this.name
    utils.debugf("gen.TypeAssertExpr::getStruct() pkgname:%s name:%s\n",this.pkgname,name)
	s = null
	pkg = GP().pkg.getPackage(this.pkgname)
	if pkg == null {
		this.check(false,"type assert: mem package not exist:" + this.pkgname)
	}
	s = pkg.getStruct(name)
	if s == null {
        this.check(false,"mem type not exist :" + name)
	}
	return s
}