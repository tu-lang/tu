use compiler.utils
use std
use compiler.gen

class Class 
{
	pkg = pkg
	name
	members     = [] // [Expression]
	initmembers = [] // [Expression]
	membervars  = [] // use by gen
	funcs       = [] // [Function] 

	father
	parser      // Parser
	type_id     = 0
	found       = false
	func init(pkg){}
}

Class::getFunc(name){
	for it : this.funcs {
		if it.name == name {
			return it
		}
	}
	return null
}

Class::getMember(name)
{
	utils.debugf("ast.Class::getMember() name:%s",name)
	for(i : this.members){
		assign = i
		var = assign.lhs
		if var.varname == this.name {
		return name
		}
	}
	for(i : this.initmembers){
		//FIXME: assign should not define
		// var = assign.lhs
		var = i.lhs
		if var.varname == name {
		return name
		}
	}
	return ""
}

Class::initClassInitFunc()
{
  	utils.debugf("ast.Class::initClassInitFunc() cls:%s",this.name)
    f = null
    for fc : this.funcs {
        if fc.name == "init" {
            f = fc
            break
        }
    }
    if f == null {
        f = this.parser.genClassInitFunc(this.name) 
		f.fntype = ClassFunc
		f.cls = this

        this.funcs[] = f
        this.parser.addFunc(this.name + f.name,f)
        if this.father != null {
          f.block.stmts[] = this.parser.genSuperInitStmt(f)
        }
    }
    if f.block == null {
        f.block = new gen.BlockStmt()
    }
	
    f.block.InsertExpressionsHead(this.initmembers)

    return true
} 

Class::checkRmSupers(){
	utils.debug("ast.Class::checkRmSupers()")
	if this.father != null return true
	for f : this.funcs {
		if f.block == null  continue
		if f.name == "init" continue
		f.block.checkAndRmFirstSuperDefine()
	}
}

Member::getarrcount(){
	arrcount = this.arrsize

	if this.isarr && this.arrvar != null {
		match type(this.arrvar) {
			type(gen.VarExpr) : arrcount = this.arrvar.expr_compile()
			type(gen.BinaryExpr) : arrcount = this.arrvar.expr_compile()
			type(gen.IntExpr) 	: arrcount = string.tonumber(this.arrvar.lit)
			_ :	this.arrvar.check(false,"unknwon type in getarrcount")
		}
	}
	this.arrsize = arrcount
	return arrcount
}
Class::virtname(){
	if this.found {
		return "virth_" + this.parser.getpkgname() + "_" + this.name
	}else{
		s = null
		if this.pkg != "" {
			pkg = compile.currentParser.pkg.getPackage(this.pkg)
			if pkg != null {
				s = pkg.getClass(this.name)
			}
		}else {
			s = compile.currentParser.pkg.getClass(this.name)
		}
		if s == null {
			this.parser.check(false,"father not exist in virtb gen")
		}
		return s.virtname()
	}
}

Class::getReal(){
    s = null
    if this.pkg != "" {
        pkg = this.parser.pkg.getPackage(this.pkg)
        if pkg != null
            s = pkg.getClass(this.name)
    }else{
        s = this.parser.pkg.getClass(this.name)
    }

    if s == null
        this.parser.check(false,"AsmError: class is not define of " + this.name)

    return s
}