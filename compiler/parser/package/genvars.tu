use parser
use internal
use ast
use std

Package::InsertInitVarExpression(expr){
	funcname = this.getInitVarsFuncName()
	f = this.getFunc(funcname,false)
    if f == null {
		p = std.head(this.parsers)
        f = new ast.Function()
        //set parser
        f.name = funcname
        f.block = new ast.Block()
        f.parser = p
        f.package = this 
        p.addFunc(f.name,f) 
    }
    f.InsertExpression(expr)
}

Package::genvarsinit(){
	mf = this.getFunc("init0",false)
    if mf == null {
		p = std.head(this.parsers)
        mf = this.InsertInitFunc(p) 
    } 

    for(pkg : packages){
        if(pkg.getFunc(this.getInitVarsFuncName(),false)){
            mf.InsertFuncall(pkg.getFullName(),this.getInitVarsFuncName())
        }
    }
}
