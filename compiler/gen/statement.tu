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
        this.genDefault(ctx,0)
    }else {
        this.compilemulti(ctx)
    }
    ctx.jmpReturn()
    return null
}

ReturnStmt::exprCast(ctx , expr, i){
    fc = ast.GF()
    defineType = null
    if std.len(fc.returnTypes) >= (i + 1) {
        defineType = fc.returnTypes[i]
    }
    if defineType != null && defineType.baseType() {
        op = new OperatorHelper()
        op.staticCompile(expr)

        // if !op.isbase && !defineType.pointer && defineType.base != ast.I64 && defineType.base != ast.U64 {
            // expr.check(false,"cast may loss data")
        // }
        compile.Cast(op.ltoken,defineType.dstCastType())
        return defineType
    }
    expr.compile(ctx,true)
    return null
}

ReturnStmt::genExpr(ctx , i){
    expr = this.ret[i]
    fType = this.exprCast(ctx,expr,i)
    if i == 0 {
        return null
    }
    fc = ast.GF()
    cur = i - 1
    stackpointer = fc.ret_stack

    ty = expr.getType(ctx)
    compile.writeln(" mov %d(%rbp) , %%rdi",stackpointer)
    if fType != null && ( fType.base == ast.F32 || fType.base == ast.F64){
        compile.PushfDst(ty,"%rdi", cur * 8)
    }else if exprIsMtype(expr,ctx) && ast.isfloattk(ty) {
        compile.PushfDst(ty,"%rdi",cur * 8)
    }else{
        compile.writeln(" mov %%rax , %d(%%rdi)",cur * 8)
    }
}

ReturnStmt::genDefault(ctx , i){
    fc = ast.GF()
    defineType = null
    if std.len(fc.returnTypes) > ( i + 1) {
        defineType = fc.returnTypes[i]
    }

    if i == 0 {
        if defineType != null{
            compile.writeln(" mov $0 , %%rax")
            if defineType.baseType() {
                compile.Cast(ast.I64,defineType.base)
            }
        }else if ast.cfg_static()
                compile.writeln(" mov $0 , %%rax")
        else compile.writeln("    lea runtime_internal_null(%%rip), %%rax")
        return null
    }

    cur = i - 1
    stackpointer = fc.ret_stack
    compile.writeln(" mov %d(%rbp) , %%rdi",stackpointer)
    if defineType != null {
        compile.writeln(" mov $0 , %%rax")
        if defineType.baseType() {
            compile.Cast(ast.I64,defineType.base)
            if ast.isfloattk(defineType.base)
                compile.PushfDst(defineType.base,"%rdi",cur)
            else 
                compile.writeln(" mov $0 , %d(%%rdi)",cur)
        }else{
            compile.writeln(" mov $0 , %d(%%rdi)",cur)
        }
    }else if ast.cfg_static() {
        compile.writeln(" mov $0 , %d(%%rdi)",cur)
    }else{
        compile.writeln("    lea runtime_internal_null(%%rip), %%rax")
        compile.writeln(" mov %%rax , %d(%%rdi)",cur)
    }
    return null
}

ReturnStmt::compilemulti(ctx){
    fc = ast.GF()

    stackpointer = fc.ret_stack
    this.check(stackpointer> 0)

    for i = fc.mcount - 1 ; i >= 0 ;i -= 1 {
        cur = i - 1
        if i == 0 {
            if std.len(this.ret) > 0 
                return this.genExpr(ctx,i)
            return this.genDefault(ctx,i)    
        }

        // missing
        if (i + 1) > std.len(this.ret) {
            this.genDefault(ctx,i)
        }else {
            this.genExpr(ctx,i)
        }
    }
    return null
}

class BreakStmt      : ast.Ast {
    breakto   = null
    func init(line,column){
        super.init(line,column)
    }  
    func toString() { return "BreakStmt()" }
}
BreakStmt::compile(ctx)
{
    utils.debugf("gen.BreakExpr::compile()")
    this.record()

    if this.breakto != null && this.breakto.hasawait {
        stmt = this.breakto
        if type(stmt) != type(ForStmt) && type(stmt) != type(WhileStmt) && type(stmt) != type(MatchStmt) {
            stmt.check(false,"brek to invalid statement")
        }
        label = stmt.breakid

        gs = new GotoStmt(label,this.line,this.column)
        return gs.compile(ctx)
    }
    
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
    continueto = null
    func init(line,column){
        super.init(line,column)
    }  
    func toString() { return "ContinueStmt()" }

}
ContinueStmt::compile(ctx)
{
    utils.debugf("gen.ContinueExpr::compile()")
    this.record()

    if this.continueto != null && this.continueto.hasawait {
        stmt = this.continueto
        if type(stmt) != type(ForStmt) && type(stmt) != type(WhileStmt)  {
            stmt.check(false,"continue to invalid statement")
        }
        label = stmt.continueid

        gs = new GotoStmt(label,this.line,this.column)
        return gs.compile(ctx)
    }
    
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
    case1 = null // future case
    func init(label,line,column){
        super.init(line,column)
    }
}

GotoStmt::compile(ctx){
    utils.debugf("gen.GotoExpr::compile()")
    this.record()

    if this.case1 != null {
        this.label = this.case1.label
    }
    if this.label == "" {
        this.check(false,"goto label is null")
    }
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

        opexpr.compile(ctx,false)
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
        return this.assign2(ctx,fcexpr)
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

        assignExpr.compile(ctx,false)
    }
    fce.freeret()
    return null
}

MultiAssignStmt::assign2(ctx,fce){

    firstexpr = this.ls[0]
    ty = firstexpr.getType(ctx)
    if ast.isfloattk(ty) {
        compile.Pushf(ty)
    }else{
        compile.Push()
    }

    for i = 0 ; i < std.len(this.ls) ;i += 1 {
        lexpr = this.ls[i]
        rexpr = new StackPosExpr(this.line,this.column)
        rexpr.isdyn = true
        rexpr.cur = i + 1
        rexpr.pos = -1

        assignExpr = new AssignExpr(lexpr.line,lexpr.column)
        assignExpr.opt = this.opt
        assignExpr.lhs = lexpr
        assignExpr.rhs = rexpr

        assignExpr.compile(ctx,false)
    }
    compile.Pop("%rdi")
    fce.dynfreeret()
    return null    
}