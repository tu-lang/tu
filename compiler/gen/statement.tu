use ast
use std

func condIsMtype(cond,ctx){
    ismtype = false
    match type(cond) {
        type(ast.StructMemberExpr) : ismtype = true
        type(ast.VarExpr) : {
            tvar = cond
            ismtype = tvar.isMemtype(ctx)
        }
        type(BinaryExpr) : {
            tvar = cond
            if tvar.opt == ast.LOGAND || tvar.opt == ast.LOGOR {
                return true
            }
            ismtype = tvar.isMemtype(ctx)
        }
    }
    return ismtype
}

ast.ForStmt::compile(ctx)
{
    record()
    if  range  return rangeFor(ctx)
    return triFor(ctx)
}
ast.ForStmt::rangeFor(ctx)
{
    c = ast.incr_labelid()
    if this.obj == null 
        parse_err("statement: for(x,y : obj) obj should pass value. line:%d column:%d",line,column)
    
    this.obj.compile(ctx)
    compile.Push()
    
    compile.writeln("   mov (%%rsp),%%rdi")
    internal.call("runtime_for_first")
    compile.Push()
    
    
    compile.writeln("L.forr.begin.%d:", c)
    
    compile.CreateCmp()
    compile.writeln("    je  L.forr.end.%d", c)

    
    if this.key{
        std.tail(ctx).createVar(this.key.varname,this.key)
        compile.writeln("   mov 8(%%rsp),%%rdi")
        compile.writeln("   mov (%%rsp),%%rsi")
        internal.call("runtime_for_get_key")
        compile.Push()

        compile.GenAddr(this.key)
        compile.Pop("%rdi")
        compile.writeln("   mov %%rdi,(%%rax)")
    }
    if this.value {
        std.tail(ctx).createVar(this.value.varname,this.value)
        compile.writeln("   mov 8(%%rsp),%%rdi")
        compile.writeln("   mov (%%rsp),%%rsi")
        internal.call("runtime_for_get_value")
        compile.Push()
        compile.GenAddr(this.value)
        compile.Pop("%rdi")
        compile.writeln("   mov %%rdi,(%%rax)")
    }

    compile.blockcreate(ctx)
    
    std.tail(ctx).point = c
    std.tail(ctx).end_str   = "L.forr.end"
    std.tail(ctx).start_str = "L.forr.begin"
    std.tail(ctx).continue_str = "L.for.continue"
    
    
    for(stmt : block.stmts){
        stmt.compile(ctx)
    }
    compile.blockdestroy(ctx)

    compile.writeln("L.for.continue.%d:",c)
    compile.writeln("   mov 8(%%rsp),%%rdi")
    compile.Pop("%rsi")
    internal.call("runtime_for_get_next")
    compile.Push()

    compile.writeln("    jmp L.forr.begin.%d",c)
    compile.writeln("L.forr.end.%d:", c)
    
    compile.writeln("   add $16,%%rsp")
    return null
}
ast.ForStmt::triFor(ctx)
{
    c = ast.incr_labelid()
    compile.blockcreate(ctx)
    this.init.compile(ctx)
    
    compile.writeln("L.for.begin.%d:", c)
    this.cond.compile(ctx)
    if !condIsMtype(this.cond,ctx) {
        internal.isTrue()
    }
    compile.CreateCmp()
    compile.writeln("    je  L.for.end.%d", c)

    std.tail(ctx).point = c
    std.tail(ctx).end_str   = "L.for.end"
    std.tail(ctx).start_str = "L.for.begin"
    std.tail(ctx).continue_str = "L.for.continue"
    
    
    for(stmt : block.stmts){
        stmt.compile(ctx)
    }
    
    compile.writeln("L.for.continue.%d:",c)
    
    this.after.compile(ctx)
    compile.blockdestroy(ctx)

    compile.writeln("    jmp L.for.begin.%d",c)
    compile.writeln("L.for.end.%d:", c)

}

ast.WhileStmt::compile(ctx)
{
    record()
    c = ast.incr_labelid()
    
    compile.writeln("L.while.begin.%d:", c)
    
    this.cond.compile(ctx)
    if !condIsMtype(this.cond,ctx){
        internal.isTrue()
    }
    compile.CreateCmp()
    compile.writeln("    je  L.while.end.%d", c)

    compile.blockcreate(ctx)
    
    std.tail(ctx).po= c
    std.tail(ctx).end_str   = "L.while.end"
    std.tail(ctx).start_str = "L.while.begin"
    
    for(stmt : block.stmts){
        stmt.compile(ctx)
    }
    compile.blockdestroy(ctx)

    compile.writeln("    jmp L.while.begin.%d",c)
    compile.writeln("L.while.end.%d:", c)
}
ExpressionStmt::compile(ctx)
{
    record()
    this.expr.compile(ctx)
}

ast.ReturnStmt::compile(ctx)
{
    record()
    
    if ret == null {
        compile.writeln("   mov $0,%%rax")
    }else{
        ret = this.ret.compile(ctx)
        if ret && type(ret) == type(ast.StructMemberExpr) {
            sm = ret
            m = sm.ret
            
            compile.Load(m)
        
        }else if ret && type(ret) == type(ast.ChainExpr) {
            ce = ret
            if ce.ret {
                compile.Load(ce.ret)
            }
        }
    }
    for(p : ctx ) {
        funcName = p.cur_funcname
        if funcName != "" 
            compile.writeln("    jmp L.return.%s",funcName)
    }
}

ast.BreakStmt::compile(ctx)
{
    record()
    
    for(c : ctx ) {
        if c.po && c.end_str != ""  {
            compile.writeln("    jmp %s.%d",c.end_str,c.point)
        }
    }
}

ast.ContinueStmt::compile(ctx)
{
    record()
    
    for ( c : ctx) {
        if c.po && c.continue_str != "" {
            compile.writeln("    jmp %s.%d", c.continue_str, c.point)
        }
        if c.po && c.start_str != "" {
            compile.writeln("    jmp %s.%d", c.start_str, c.point)
        }
    }
}

ast.MatchCaseExpr::compile(ctx){
    record()
    compile.writeln("%s:",label)
    
    if block != null {
        for(stmt : block.stmts){
            stmt.compile(ctx)
        } 
    }
    compile.writeln("   jmp %s", endLabel)
    return this
}

ast.MatchStmt::compile(ctx){
    record()
    mainPoint = ast.incr_labelid()
    endLabel = "L.match.end." + mainPoint
    
    for(cs : this.cases){
        c = ast.incr_labelid()
        cs.label = "L.match.case." + c
        cs.endLabel = endLabel
    }
    
    if defaultCase == null {
        defaultCase = new MatchCaseExpr(line,column)
        defaultCase.matchCond = this.cond
    }
    defaultCase.label = "L.match.default." + compile.count++
    defaultCase.endLabel = endLabel
    
    for(cs : this.cases){
        be = new BinaryExpr(cs.line,cs.column)
        be.lhs = cs.matchCond
        be.opt = ast.EQ
        be.rhs = cs.cond
        be.compile(ctx)
        
        if !condIsMtype(be,ctx)
            internal.isTrue()
        
        compile.writeln("    cmp $1, %%rax")
        compile.writeln("    je  %s", cs.label)
    }
    
    compile.writeln("   jmp %s", defaultCase.label)
    
    compile.blockcreate(ctx)
    for(cs : this.cases){
        cs.compile(ctx)
    }
    defaultCase.compile(ctx)
    compile.blockdestroy(ctx)

    compile.writeln("L.match.end.%d:",mainPoint)
    return null
}

ast.IfCaseExpr::compile(ctx){
    record()
    compile.writeln("%s:",label)
    if block {
        for(stmt : block.stmts){
            stmt.compile(ctx)
        } 
    }
    compile.writeln("   jmp %s", endLabel)
    return this
}

ast.IfStmt::compile(ctx){
    record()
    mainPoint = ast.incr_labelid()
    endLabel = "L.if.end." + mainPoint
    
    for(cs : this.cases){
        cs.label  = "L.if.case." + ast.incr_labelid()
        cs.endLabel = endLabel
    }
    if elseCase {
        elseCase.label = "L.if.case." + ast.incr_compileidx()
        elseCase.endLabel = endLabel
    }

    for(cs : this.cases){
        cs.cond.compile(ctx)
        if !condIsMtype(cs.cond,ctx)
            internal.isTrue()
        compile.writeln("    cmp $1, %%rax")
        compile.writeln("    je  %s", cs.label)
    }
    
    if elseCase compile.writeln("   jmp %s", elseCase.label)
    
    compile.writeln("   jmp L.if.end.%d", mainPoint)
    
    compile.blockcreate(ctx)
    for(cs : this.cases){
        cs.compile(ctx)
    }
    if elseCase elseCase.compile(ctx)
    compile.blockdestroy(ctx)

    compile.writeln("L.if.end.%d:",mainPoint)
    return null
}

ast.GotoStmt::compile(ctx){
    record()
    compile.writeln("   jmp %s",label)
    return null
}