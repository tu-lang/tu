
class Context {
    vars         = {} # map{string:VarExpr}
    isFuncArg    = {} # map{string,bool}

    cur_funcname = ""
    end_str      = ""
    start_str    = ""
    continue_str = ""
    point        = 0
}
Context::hasVar(varname)
{
    return this.vars[varname] != null
}

Context::createVar(varname,ident)
{
    this.vars[varname] = ident
}
Context::getVar(varname)
{
    if std.len(this.vars) < 1 return null
    if this.vars[varname] != null {
        return this.vars[varname]
    } 
    return null
}

func getVar(ctx , varname)
{
    hasctx = false
    ret    = null
    for(c : ctx){
        if var = c.getVar(varname) {
            hasctx = true
            if GF().locals[varname] != null
                ret = GF().locals[varname]
            else if GF().params_var[varname] != null
                ret = GF().params_var[varname]
            if ret != null return ret
            return null
        }
    }
    if !hasctx {
        if GF().locals[varname] != null
            ret = GF().locals[varname]
        else if GF().params_var[varname] != null
            ret = GF().params_var[varname]
        if ret == null return null

        std.tail(ctx).createVar(ret.varname,ret)
    }

    return ret
}


