use compiler.ast
use std


class ReturnStmt     : ast.Ast { 
    ret = []
    func init(line,column){
        super.init(line,column)
    }
    func toString() {
        str = "ReturnStmt("
        for v : this.ret {
            str += "ret="
            str += v.toString()
        }
        str += ")"
        return str
    } 
}
ReturnStmt::compile(ctx)
{
    utils.debugf("gen.ReturnExpr::compile()")
    this.record()
    
    fc = ast.GF()
    if fc.mcount == 0 {
        if ast.cfg_static()
             compile.writeln("   mov $0 , %%rax")
        else compile.writeln("   lea runtime_internal_null(%%rip) , %%rax")
    }else {
        this.compilemulti(ctx)
    }
    for(i = std.len(ctx.ctxs) - 1 ; i >= 0 ; i -= 1){
        p = ctx.ctxs[i]
        funcName = p.cur_funcname
        if funcName != "" {
            compile.writeln("    jmp %s.L.return.%s",compile.currentParser.label(),funcName)
            return null
        } 
    }
    return null
}
ReturnStmt::compilemulti(ctx){
    fc = ast.GF()
    if fc.mcount == 1 {
        if std.len(this.ret) == 0{
            if ast.cfg_static()
                compile.writeln(" mov $0 , %%rax")
            else compile.writeln("    lea runtime_internal_null(%%rip), %%rax")
        }else if std.len(this.ret) == 1 {
            this.ret[0].compile(ctx,true)
        }else{
            this.ret[0].check(false,"should not be here")
        }
    }else{ //>=2
        stackpointer = fc.ret_stack
        this.ret[0].check(stackpointer > 0)
        for i = fc.mcount; i >= 0 ; i -= 1 {
            cur = i - 1 - 1
            if i == 1 { 
                if std.len(this.ret) > 0 {
                    this.ret[0].compile(ctx,true)
                }else{
                    if ast.cfg_static()
                         compile.writeln(" mov $0 , %%rax")
                    else compile.writeln("    lea runtime_internal_null(%%rip), %%rax")
                }
                break
            }
            if i > std.len(this.ret) {
                compile.writeln(" mov %d(%rbp) , %%rdi",stackpointer)
                if ast.cfg_static() {
                    compile.writeln(" mov $0 , %d(%%rdi)",cur)
                }else{
                    compile.writeln("    lea runtime_internal_null(%%rip), %%rax")
                    compile.writeln(" mov %%rax , %d(%%rdi)",cur)
                }
            }else{ 
                expr = this.ret[i - 1]
                expr.compile(ctx,true)
                ty = expr.getType(ctx)
                compile.writeln(" mov %d(%rbp) , %%rdi",stackpointer)

                if exprIsMtype(expr,ctx) && ast.isfloattk(ty) {
                    compile.PushfDst(ty,"%rdi",cur * 8)
                }else {
                    compile.writeln("   mov %%rax , %d(%%rdi)", cur * 8)
                }
            }

        }
    }    
}
//TODO: not parser
class BreakStmt      : ast.Ast {
    func init(line,column){
        super.init(line,column)
    }  
    func toString() { return "BreakStmt()" }
}
BreakStmt::compile(ctx)
{
    utils.debugf("gen.BreakExpr::compile()")
    this.record()
    
    for(i = std.len(ctx.ctxs) - 1 ; i >= 0 ; i -= 1){
        c = ctx.ctxs[i]
        if c.point && c.end_str != ""  {
            compile.writeln("    jmp %s.%d",c.end_str,c.point)
            return null
        }
    }
    return null
}
class ContinueStmt   : ast.Ast {
    func init(line,column){
        super.init(line,column)
    }  
    func toString() { return "ContinueStmt()" }

}
ContinueStmt::compile(ctx)
{
    utils.debugf("gen.ContinueExpr::compile()")
    this.record()
    
    for(i = std.len(ctx.ctxs) - 1 ; i >= 0 ; i -= 1){
        c = ctx.ctxs[i]
        if c.point && c.continue_str != "" {
            compile.writeln("    jmp %s.%d", c.continue_str, c.point)
            return null
        }
        if c.point && c.start_str != "" {
            compile.writeln("    jmp %s.%d", c.start_str, c.point)
            return null
        }
    }
    return null
}

class GotoStmt   : ast.Ast {
    label = label
    func init(label,line,column){
        super.init(line,column)
    }
}
GotoStmt::compile(ctx){
    utils.debugf("gen.GotoExpr::compile()")
    this.record()
    compile.writeln("   jmp %s",this.label)
    return null
}

class MultiAssignStmt : ast.Ast {
    ls = []
    rs = []
    opt
    fn init(line,column){
        super.init(line,column)
    }
}

MultiAssignStmt::toString(){
    ret = "("

    for it : this.ls {
        ret += it.toString()
        ret += ","
    }
    ret += ")"
    ret += ast.getTokenString(this.opt)
    ret += "("
    for it : this.rs {
        ret += it.toString()
        ret += ","
    }
    ret += ")"
    return ret    
}

MultiAssignStmt::compile(ctx){
    if std.len(this.ls) == std.len(this.rs) {
        return this.compile1(ctx)
    }

    if std.len(this.rs) > 1 {
        this.rs[0].check(false,"multiassign right is != 1")
    }

    return this.compile2(ctx)
}

MultiAssignStmt::compile1(ctx){
    for i = 0 ; i < std.len(this.ls) ; i += 1 {
        lexpr = this.ls[i]
        rexpr = this.rs[i]

        opexpr = new AssignExpr(lexpr.line,lexpr.column)
        opexpr.opt = this.opt
        opexpr.lhs = lexpr
        opexpr.rhs = rexpr

        opexpr.compile(ctx)
    }
    return null
}

MultiAssignStmt::compile2(ctx){
    rex = this.rs[0]
    ret = rex.compile(ctx,false)
    if ret == null || type(ret) != type(FunCallExpr) {
        rex.check(false,"right must be funcall in multi assign statement")
    }
    fcexpr = ret
    isdyn = fcexpr.is_dyn

    if isdyn {
        return this.assign2(ctx)
    }
    return this.assign(ctx,fcexpr)
}

MultiAssignStmt::assign(ctx, fce){
    fc = fce.fcs
    if fc.mcount != 0 {
        firstexpr = this.ls[0]
        ty = firstexpr.getType(ctx)
        if ast.isfloattk(ty) {
            compile.Pushf(ty)
        }else{
            compile.Push()
        }
    }

    for i = 0 ; i < std.len(this.ls) ;i += 1 {
        lexpr = this.ls[i]
        rexpr = new StackPosExpr(this.line,this.column)
        rexpr.total = fc.mcount
        rexpr.cur = i + 1
        rexpr.pos = -1

        assignExpr = new AssignExpr(lexpr.line,lexpr.column)
        assignExpr.opt = this.opt
        assignExpr.lhs = lexpr
        assignExpr.rhs = rexpr

        assignExpr.compile(ctx)
    }
    fce.freeret()
    return null
}

MultiAssignStmt::assign2(ctx){
    utils.panic("should not be assign2 here")
}