use compiler.utils
use std


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

//parser phase
Context::getVar(gf , varname)
{
    hasctx = false
    ret = null
    for(i = std.len(this.ctxs) - 1 ; i >= 0 ; i -= 1){
        ctx = this.ctxs[i]
        var =  ctx.getVar(varname)
        if  var != null {
            hasctx = true
            if gf.FindLocalVar(var.varname) != null {
                ret = gf.FindLocalVar(var.varname)
            }
            if (ret != null) return ret
            utils.warn(
                "parser: ctx not var: %s,but local has var filename:%s"
                ,varname,gf.parser.filename
            )
            return null
        }
    }
    if !hasctx {
        if gf.FindLocalVar(varname) != null {
            ret = gf.FindLocalVar(varname)
        }
        if ret != null {
            utils.errorf(
                "parser: ctx not var: %s,but local has var filename:%s line:%d"
                ,varname,gf.parser.filename,ret.line
            )
        }
    }

    return null
}