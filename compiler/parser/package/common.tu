use compiler.utils
use compiler.ast
use compiler.parser.package
use compiler.gen
use compiler.compile

uniquesig = "initvars_" + utils.strRand()

Package::getInitVarsFuncName(){
	return uniquesig
}

Package::initClassInitFunc(name)
{
    utils.debug("parser.package.Package::initClassInitFunc() name:%s",name)
	if this.classes[name] == null
		return false
	cs = this.classes[name]
	f = null
    for(var : cs.funcs){
        if var.name == "init" {
            f = var
            break
        }
    }
    if f == null {
		p = std.head(this.parsers)
        f = p.genClassInitFunc(name)
        cs.funcs[] = f 
        p.addFunc(cs.name + f.name,f)
    }

    if f.block == null {
        f.block = new gen.BlockStmt()
    }
    f.block.InsertExpressionsHead(cs.initmembers)
    return true
}

Package::getImport(name){
    if name == "" || name == null return this.full_package
    if this.imports[name] != null {
        return this.imports[name]
    }
    return ""
}
Package::getPackage(packagename){
    entire = false
    for(i : this.imports){
        if ( packagename != "" && packagename == i){
            entire = true
            break
        }
    }
    pkg = null
    if entire{
        if(package.packages[packagename] != null)
            pkg = package.packages[packagename]
    }else{
        pkgname = ""
        if(packagename == ""){
            pkgname =  this.full_package
        }else{
            if(this.imports[packagename] != null){
                pkgname = this.imports[packagename]
            }
        }
        if(package.packages[pkgname] != null)
            pkg = package.packages[pkgname]
    }
    return pkg
}
func GP(){
    return compile.currentParser
}