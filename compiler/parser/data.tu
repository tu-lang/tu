use std
use fmt

Parser::addFunc(name, f)
{
    if name == "init" {
        f.name = f.name + this.pkg.geninitid()
        name = f.name
        this.pkg.inits[] = f
    }
    if f.isExtern   extern_funcs[name] = f
    else            funcs[name] = f
}

Parser::hasFunc(name, is_extern)
{
    if name == "init" { return false}

    if is_extern  return std.exist(name,extern_funcs)
    else          return std.exist(name,funcs)
}

Parser::getFunc(name, is_extern)
{
    if is_extern {
        if std.exist(name,extern_funcs) 
            return extern_funcs[name]
    }else {
        if std.exist(name,funcs)
            return funcs[name]
    }
    return null
}

Parser::getGvar(name){
    if std.exist(name,gvars) 
        return gvars[name]
    return null
}