use std
use fmt
use parser.package

Parser::addFunc(name, f)
{
    if name == "init" {
        f.name = f.name + this.pkg.geninitid()
        name = f.name
        this.pkg.inits[] = f
    }
    if f.isExtern   this.extern_funcs[name] = f
    else            this.funcs[name] = f
}

Parser::hasFunc(name, is_extern)
{
    if name == "init" { return false}

    if is_extern  return std.exist(name,this.extern_funcs)
    else          return std.exist(name,this.funcs)
}

Parser::getFunc(name, is_extern)
{
    if is_extern {
        if std.exist(name,this.extern_funcs) 
            return this.extern_funcs[name]
    }else {
        if std.exist(name,this.funcs)
            return this.funcs[name]
    }
    return null
}

Parser::getGvar(name){
    if std.exist(name,this.gvars) 
        return this.gvars[name]
    return null
}
Parser::getGlobalVar(pkgname ,varname){
    entire = false
    for(i : this.import){
        if ( pkgname != "" && pkgname == i){
            entire = true
            break
        }
    }
    pkg = null
    if entire {
        if package.packages[pkgname] != null 
            pkg = package.packages[pkgname]
    }else{
        pkgname2 = ""
        if pkgname == "" {
            pkgname2 = this.getpkgname()
        }else{
            if this.import[pkgname] != null {
                pkgname2 = this.import[pkgname]
            }
        }
        if package.packages[pkgname2] != null {
            pkg = package.packages[pkgname2]
        }
    }
    if (pkg == null){
        return null
    }
    return pkg.getGlobalVar(varname)
}
Parser::getGlobalFunc(pkgname ,varname,is_extern){
    fn = null
    if package.packages[pkgname] != null {
        fn = package.packages[pkgname].getFunc(varname,is_extern)
    }else if pkgname != "" {
        return null
    }
    if(fn == null){
        if package.packages[this.getpkgname()] != null {
            pkg = package.packages[this.getpkgname()]
            fn = pkg.getFunc(varname,is_extern)
        }
    }
    return fn
}