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
TypeAssertExpr::toString(s) { 
	return fmt.sprintf("TypeAssertExpr(%s.%s)"
		this.pkgname,this.name
	)
}

TypeAssertExpr::compile(ctx){
    return null

}
TypeAssertExpr::getStruct(){
	pkg = this.pkgname
	name = this.name
    utils.debugf("gen.TypeAssertExpr::getStruct() pkgname:%s name:%s\n",pkg,name)
	s = null
	if GP().import[pkg] != null {
		pkg = GP().import[pkg]
	}
	if package.packages[pkg] == null {
		this.check(false,"mem package not exist:" + pkg)
	}
	s = package.packages[pkg].getStruct(name)
	if s == null {
        this.check(false,"mem type not exist :" + name)
	}
	return s
}