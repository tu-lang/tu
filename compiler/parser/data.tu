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
    pkg = this.pkg.getPackage(pkgname)
    if (pkg == null){
        return null
    }
    return pkg.getGlobalVar(varname)
}
Parser::getGlobalFunc(pkgname ,varname,is_extern){
    p = this.pkg.getPackage(pkgname)
    if p == null return null

    return p.getFunc(varname,is_extern)
}