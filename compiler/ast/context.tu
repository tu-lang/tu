use compiler.utils
use std

class Ctx {
    level        = 0
    vars         = {} // map{string:VarExpr}
    isFuncArg    = {} // map{string,bool}

    cur_funcname = ""
    end_str      = ""
    start_str    = ""
    continue_str = ""
    point        = 0

    //for future async
    breakto continueto
}

Ctx::createVar(varname,ident)
{
    this.vars[varname] = ident
}
Ctx::getVar(varname)
{
    if this.vars[varname] != null {
        return this.vars[varname]
    } 
    return null
}

//compile phase
Context::getLocalVar(varname)
{
    var = GF().FindLocalVar(varname)
    if var != null return var

    var = GP().getGlobalVar("",varname)
    if var != null return var

    utils.debug(
        "variable:%s not define in local or params or global filename:%s"
        ,varname,GF().parser.filename
    )
    return null
}