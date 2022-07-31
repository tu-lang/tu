
class Context{
    # map[string]VarExpr
    vars
    # map[string]bool
    isFuncArg

    # context
    cur_funcname 
    end_str
    start_str
    continue_str
    point

}
Context::hasVar(varname)
{
    return std.exist(vars,varname)
}

Context::createVar(varname,ident)
{
    vars[varname] = ident
}
Context::getVar(varname)
{
    if std.len(vars) < 1 return null
    if std.exist(vars,varname) {
        return vars[varname]
    } 
    return null
}

func getVar(ctx , varname)
{
    for(c : ctx){
        var = c.getVar(varname) 
        if var != null {
            return var
        }
    }
    return null
}


