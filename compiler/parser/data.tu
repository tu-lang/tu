
Parser::addFunc(name, f)
{
    if f.isExtern
        extern_funcs.insert(std::make_pair(name,f))
    else
        funcs.insert(std::make_pair(name,f))
}

Parser::hasFunc(name, is_extern)
{
    if is_extern
        return extern_funcs.count(name) == 1
    else
        return funcs.count(name) == 1
}

Parser::getFunc(name, is_extern)
{
    if is_extern{
        if f = extern_funcs.find(name;f != funcs.end())
            return f.second
    }else{
        if f = funcs.find(name;f != funcs.end())
            return f.second
    }
    return null
}

Parser::getGvar(name){
    if std.len(gvars,name)
        return gvars[name]
    return null
}