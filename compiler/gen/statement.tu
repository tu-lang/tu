
condIsMtype(cond,ctx){
    ismtype = false
    match type(cond) {
        type(ast.StructMemberExpr) : ismtype = true
        type(VarExpr) : {
            tvar = cond
            ismtype = tvar.isMemtype(ctx)
        }
        type(BinaryExpr) : {
            tvar = cond
            ismtype = tvar.isMemtype(ctx)
        }
    }
    return ismtype
}

ForStmt::compile(ctx)
{
    record()
    if  range  return rangeFor(ctx)
    return triFor(ctx)
}
ForStmt::rangeFor(ctx)
{
    c = ast.incr_compileridx()
    if this.obj == null 
        parse_err("statement: for(x,y : obj) obj should pass value. line:%d column:%d",line,column)
    
    this.obj.compile(ctx)
    Compiler::Push()
    
    Compiler::writeln("   mov (%%rsp),%%rdi")
    internal.call("runtime_for_first")
    Compiler::Push()
    
    
    Compiler::writeln("L.forr.begin.%d:", c)
    
    Compiler::CreateCmp()
    Compiler::writeln("    je  L.forr.end.%d", c)

    
    if this.key{
        (std.back(ctx)).createVar(this.key.varname,this.key)
        Compiler::writeln("   mov 8(%%rsp),%%rdi")
        Compiler::writeln("   mov (%%rsp),%%rsi")
        internal.call("runtime_for_get_key")
        Compiler::Push()

        Compiler::GenAddr(this.key)
        Compiler::Pop("%rdi")
        Compiler::writeln("   mov %%rdi,(%%rax)")
    }
    if this.value {
        (std.back(ctx)).createVar(this.value.varname,this.value)
        Compiler::writeln("   mov 8(%%rsp),%%rdi")
        Compiler::writeln("   mov (%%rsp),%%rsi")
        internal.call("runtime_for_get_value")
        Compiler::Push()
        Compiler::GenAddr(this.value)
        Compiler::Pop("%rdi")
        Compiler::writeln("   mov %%rdi,(%%rax)")
    }

    Compiler::this.enterContext(ctx)
    
    std.back(ctx).po= c
    std.back(ctx).end_str   = "L.forr.end"
    std.back(ctx).start_str = "L.forr.begin"
    std.back(ctx).continue_str = "L.for.continue"
    
    
    for(stmt : block.stmts){
        stmt.compile(ctx)
    }
    Compiler::this.leaveContext(ctx)

    Compiler::writeln("L.for.continue.%d:",c)
    Compiler::writeln("   mov 8(%%rsp),%%rdi")
    Compiler::Pop("%rsi")
    internal.call("runtime_for_get_next")
    Compiler::Push()

    Compiler::writeln("    jmp L.forr.begin.%d",c)
    Compiler::writeln("L.forr.end.%d:", c)
    
    Compiler::writeln("   add $16,%%rsp")
    return null
}
ForStmt::triFor(ctx)
{
    c = ast.incr_compileridx()
    Compiler::this.enterContext(ctx)
    this.init.compile(ctx)
    
    Compiler::writeln("L.for.begin.%d:", c)
    this.cond.compile(ctx)
    if !condIsMtype(this.cond,ctx) {
        internal.isTrue()
    }
    Compiler::CreateCmp()
    Compiler::writeln("    je  L.for.end.%d", c)

    std.back(ctx).po= c
    std.back(ctx).end_str   = "L.for.end"
    std.back(ctx).start_str = "L.for.begin"
    std.back(ctx).continue_str = "L.for.continue"
    
    
    for(stmt : block.stmts){
        stmt.compile(ctx)
    }
    
    Compiler::writeln("L.for.continue.%d:",c)
    
    this.after.compile(ctx)
    Compiler::this.leaveContext(ctx)

    Compiler::writeln("    jmp L.for.begin.%d",c)
    Compiler::writeln("L.for.end.%d:", c)

}

WhileStmt::compile(ctx)
{
    record()
    c = ast.incr_compileridx()
    
    Compiler::writeln("L.while.begin.%d:", c)
    
    this.cond.compile(ctx)
    if !condIsMtype(this.cond,ctx){
        internal.isTrue()
    }
    Compiler::CreateCmp()
    Compiler::writeln("    je  L.while.end.%d", c)

    Compiler::this.enterContext(ctx)
    
    std.back(ctx).po= c
    std.back(ctx).end_str   = "L.while.end"
    std.back(ctx).start_str = "L.while.begin"
    
    for(stmt : block.stmts){
        stmt.compile(ctx)
    }
    Compiler::this.leaveContext(ctx)

    Compiler::writeln("    jmp L.while.begin.%d",c)
    Compiler::writeln("L.while.end.%d:", c)
}
ExpressionStmt::compile(ctx)
{
    record()
    this.expr.compile(ctx)
}

ReturnStmt::compile(ctx)
{
    record()
    
    if ret == null{
        Compiler::writeln("   mov $0,%%rax")
    }else{
        ret = this.ret.compile(ctx)
        if ret && type(ret) == type(ast.StructMemberExpr) {
            sm = ret
            m = sm.ret
            
            Compiler::Load(m)
        
        }else if ret && type(ret) == type(ChainExpr) {
            ce = ret
            if ce.ret {
                Compiler::Load(ce.ret)
            }
        }
    }
    for(p : ctx ) {
        funcName = p.cur_funcname
        if funcName != "" 
            Compiler::writeln("    jmp L.return.%s",funcName)
    }
}

BreakStmt::compile(ctx)
{
    record()
    
    for(c : ctx ) {
        if c.po && c.end_str != ""  {
            Compiler::writeln("    jmp %s.%d",c.end_str,c.point)
        }
    }
}

ContinueStmt::compile(ctx)
{
    record()
    
    for ( c : ctx) {
        if c.po&& !c.continue_str.empty(){
            Compiler::writeln("    jmp %s.%d", c.continue_str, c.point)
        }
        if (c.po&& !c.start_str.empty()) {
            Compiler::writeln("    jmp %s.%d", c.start_str, c.point)
        }
    }
}

MatchCaseExpr::compile(ctx){
    record()
    Compiler::writeln("%s:",label)
    
    if block{
        for(stmt : block.stmts){
            stmt.compile(ctx)
        } 
    }
    Compiler::writeln("   jmp %s", endLabel)
    return this
}

MatchStmt::compile(ctx){
    record()
    mainPo= ast.incr_compileridx()
    endLabel = "L.match.end." + mainPoint
    
    for(cs : this.cases){
        c = ast.incr_compileridx()
        cs.label = "L.match.case." + c
        cs.endLabel = endLabel
    }
    
    if defaultCase == null{
        defaultCase = new MatchCaseExpr(line,column)
        defaultCase.matchCond = this.cond
    }
    defaultCase.label = "L.match.default." + Compiler::count++
    defaultCase.endLabel = endLabel
    
    for(cs : this.cases){
        BinaryExpr be(cs.line,cs.column)
        be.lhs = cs.matchCond
        be.opt = EQ
        be.rhs = cs.cond
        be.compile(ctx)
        
        if !condIsMtype(&be,ctx)
            internal.isTrue()
        
        Compiler::writeln("    cmp $1, %%rax")
        Compiler::writeln("    je  %s", cs.label)
    }
    
    Compiler::writeln("   jmp %s", defaultCase.label)
    
    Compiler::this.enterContext(ctx)
    for(cs : this.cases){
        
        cs.compile(ctx)
    }
    defaultCase.compile(ctx)
    Compiler::this.leaveContext(ctx)

    
    Compiler::writeln("L.match.end.%d:",mainPoint)
    return null
}

IfCaseExpr::compile(ctx){
    record()
    Compiler::writeln("%s:",label)
    if block {
        for(stmt : block.stmts){
            stmt.compile(ctx)
        } 
    }
    Compiler::writeln("   jmp %s", endLabel)
    return this
}

IfStmt::compile(ctx){
    record()
    mainPo = ast.incr_compileridx()
    endLabel = "L.if.end." + mainPoint
    
    for(cs : this.cases){
        cs.label  = "L.if.case." + Compiler::count ++
        cs.endLabel = endLabel
    }
    if elseCase {
        elseCase.label = "L.if.case." + Compiler::count ++
        elseCase.endLabel = endLabel
    }

    for(cs : this.cases){
        cs.cond.compile(ctx)
        if !condIsMtype(cs.cond,ctx)
            internal.isTrue()
        Compiler::writeln("    cmp $1, %%rax")
        Compiler::writeln("    je  %s", cs.label)
    }
    
    if (elseCase) Compiler::writeln("   jmp %s", elseCase.label)
    
    Compiler::writeln("   jmp L.if.end.%d", mainPoint)
    
    Compiler::this.enterContext(ctx)
    for(cs : this.cases){
        cs.compile(ctx)
    }
    if elseCase elseCase.compile(ctx)
    Compiler::this.leaveContext(ctx)

    Compiler::writeln("L.if.end.%d:",mainPoint)
    return null
}

GotoStmt::compile(ctx){
    record()
    Compiler::writeln("   jmp %s",label)
    return null
}