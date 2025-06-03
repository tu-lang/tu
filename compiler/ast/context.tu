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

    if GF().fntype == ClosureFunc && GF().parent != null {
        var = GF().parent.FindLocalVar(varname)
        if var != null
            return var
    }

    utils.debug(
        "variable:%s not define in local or params or global filename:%s"
        ,varname,GF().parser.filename
    )
    return null
}

Context::jmpReturn(){
    for i = std.len(this.ctxs) - 1 ; i >= 0 ; i -= 1 {
        p = this.ctxs[i]
        funcName = p.cur_funcname
        if funcName != "" {
            compile.writeln("    jmp %s.L.return.%s",compile.currentParser.label(),funcName)
            return null
        } 
    }
}