use compiler.utils
use std

class Ctx {
    vars         = {} # map{string:VarExpr}
    isFuncArg    = {} # map{string,bool}

    cur_funcname = ""
    end_str      = ""
    start_str    = ""
    continue_str = ""
    point        = 0
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

class Context {
    level = 0
    ctxs = [] //Ctx
}
Context::hasVar(varname)
{
    for(i = std.len(this.ctxs) - 1 ; i >= 0 ; i -= 1){
        ctx = this.ctxs[i]
        var = ctx.getVar(varname)
        if var != null {
            return ctx
        }
    }
    return null
}

Context::getOrNewVar(varname)
{
    // utils.debugf("ast.getVar: ctx.len:%d varname:%s",std.len(ctx),varname)
    hasctx = false
    ret    = null
    for(i = std.len(this.ctxs) - 1 ; i >= 0 ; i -= 1){
        c = this.ctxs[i]
        var = c.getVar(varname)
        if var != null {
            hasctx = true
            if GF().FindLocalVar(c.level,varname) != null {
                ret = GF().FindLocalVar(c.level,varname)
            }else if GF().params_var[varname] != null
                ret = GF().params_var[varname]
            if ret != null return ret
            return null
        }
    }
    if !hasctx {
        if GF().FindLocalVar(this.toplevel(),varname) != null
            ret = GF().FindLocalVar(varname)
        else if GF().params_var[varname] != null
            ret = GF().params_var[varname]
        else if GP().getGlobalVar("",varname) != null 
            return GP().getGlobalVar("",varname)
        if ret == null return null

        this.top().createVar(ret.varname,ret)
    }

    return ret
}
Context::create(){
    temp = new ast.Ctx()
    temp.end_str = ""
    temp.start_str = ""
    temp.continue_str = ""

    temp.level = this.level
    this.level += 1
    this.ctxs[] = temp
}
Context::destroy(){
    return std.pop(this.ctxs)
}
Context::cancel(){
    this.destroy()
    this.level -= 1
}
Context::top(){
    return std.tail(this.ctxs)
}
Context::toplevel(){
    return this.top().level
}
Context::createVar(varname ,var){
    this.top().createVar(varname,var)
}

Context::getVar(gf , varname)
{
    hasctx = false
    ret = null
    for(i = std.len(this.ctxs) - 1 ; i >= 0 ; i -= 1){
        ctx = this.ctxs[i]
        var =  ctx.getVar(varname)
        if  var != null {
            hasctx = true
            if gf.FindLocalVar(ctx.level,varname) != null {
                ret = gf.FindLocalVar(ctx.level,varname)
            }else if gf.params_var[varname] != null
                ret = gf.params_var[varname]
            if (ret != null) return ret
            return null
        }
    }
    if !hasctx {
        if gf.FindLocalVar(this.toplevel(),varname) != null {
            ret = gf.FindLocalVar(this.toplevel(),varname)
        }
        else if gf.params_var[varname] != null
            ret = gf.params_var[varname]
        if ret != null {
            utils.errorf(
                "parser: ctx not var: %s,but local has var filename:%s line:%d"
                ,varname,gf.parser.filename,ret.line
            )
        }
    }

    return null
}