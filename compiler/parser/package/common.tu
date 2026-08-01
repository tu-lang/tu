use compiler.utils
use compiler.ast
use compiler.parser.package
use compiler.gen
use compiler.compile

uniquesig = "initvars_" + utils.strRand()

Package::getInitVarsFuncName(){
	return uniquesig
}
Package::getuid(){
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
    // Full package keys (incl. alias-resolved library "io") before short-name self
    if name == this.full_package
        return this.full_package
    if package.packages[name] != null
        return name
    // Own short name only when no top-level package owns that key
    if name == this.package
        return this.full_package
    return ""
}
Package::getPackage(packagename){
    pkg = null
    pkgname = ""
    if packagename == "" || packagename == null {
        pkgname = this.full_package
    } else if this.imports[packagename] != null {
        pkgname = this.imports[packagename]
    } else if package.packages[packagename] != null {
        pkgname = packagename
    } else if packagename == this.package {
        pkgname = this.full_package
    } else {
        for(i : this.imports){
            if packagename == i {
                pkgname = packagename
                break
            }
        }
    }
    if pkgname != "" && package.packages[pkgname] != null
        pkg = package.packages[pkgname]
    return pkg
}
func GP(){
    return compile.currentParser
}