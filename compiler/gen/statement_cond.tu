use ast
use std

class ForStmt : ast.Ast {
    func init(line,column){
        //TODO: closure call super(line,column)
        super.init(line,column)
    }
    init
    cond
    after
    block

    range = false
    key
    value
    obj
}
ForStmt::toString() {
    str = "ForStmt("
    str += " init="  + this.init.toString()
    str += ",cond="  + this.cond.toString()
    str += ",after=" + this.after.toString()
    str += ",exprs=["
    for (e : this.block.stmts) {
        str += e.toString()
        str += ","
    }
    str += "])"
    return str
}

ForStmt::compile(ctx)
{
    this.record()
    if  this.range  return this.rangeFor(ctx)
    return this.triFor(ctx)
}
ForStmt::rangeFor(ctx)
{
    c = ast.incr_labelid()
    if this.obj == null 
        this.panic("statement: for(x,y : obj) obj should pass value. line:%d column:%d",this.line,this.column)
    
    this.obj.compile(ctx)
    compile.Push()
    
    compile.writeln("   mov (%%rsp),%%rdi")
    internal.call("runtime_for_first")
    compile.Push()
    
    
    compile.writeln("L.forr.begin.%d:", c)
    
    compile.CreateCmp()
    compile.writeln("    je  L.forr.end.%d", c)

    
    if this.key {
        std.tail(ctx).createVar(this.key.varname,this.key)
        compile.writeln("   mov 8(%%rsp),%%rdi")
        compile.writeln("   mov (%%rsp),%%rsi")
        internal.call("runtime_for_get_key")
        compile.Push()

        compile.GenAddr(this.key.getVar(ctx))
        compile.Pop("%rdi")
        compile.writeln("   mov %%rdi,(%%rax)")
    }
    if this.value {
        std.tail(ctx).createVar(this.value.varname,this.value)
        compile.writeln("   mov 8(%%rsp),%%rdi")
        compile.writeln("   mov (%%rsp),%%rsi")
        internal.call("runtime_for_get_value")
        compile.Push()
        compile.GenAddr(this.value.getVar(ctx))
        compile.Pop("%rdi")
        compile.writeln("   mov %%rdi,(%%rax)")
    }

    compile.blockcreate(ctx)
    
    std.tail(ctx).point = c
    std.tail(ctx).end_str   = "L.forr.end"
    std.tail(ctx).start_str = "L.forr.begin"
    std.tail(ctx).continue_str = "L.for.continue"
    
    
    for(stmt : this.block.stmts){
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
ForStmt::triFor(ctx)
{
    c = ast.incr_labelid()
    compile.blockcreate(ctx)
    this.init.compile(ctx)
    
    compile.writeln("L.for.begin.%d:", c)
    this.cond.compile(ctx)
    if !exprIsMtype(this.cond,ctx) {
        internal.isTrue()
    }
    compile.CreateCmp()
    compile.writeln("    je  L.for.end.%d", c)

    std.tail(ctx).point = c
    std.tail(ctx).end_str   = "L.for.end"
    std.tail(ctx).start_str = "L.for.begin"
    std.tail(ctx).continue_str = "L.for.continue"
    
    
    for(stmt : this.block.stmts){
        stmt.compile(ctx)
    }
    
    compile.writeln("L.for.continue.%d:",c)
    
    this.after.compile(ctx)
    compile.blockdestroy(ctx)

    compile.writeln("    jmp L.for.begin.%d",c)
    compile.writeln("L.for.end.%d:", c)

}
class WhileStmt : ast.Ast {
    cond
    block
    dead = false
    func init(line,column){
        super.init(line,column)
    }
}
WhileStmt::toString() {
    str = "WhileStmt(cond="
    str += this.cond.toString()
    str += ",exprs=["
    for (e : this.block.stmts) {
        str += e.toString()
        str += ","
    }
    str += "])"
    return str
}
WhileStmt::compile(ctx)
{
    if this.dead return this.dead_compile(ctx)
    this.record()
    c = ast.incr_labelid()
    
    compile.writeln("L.while.begin.%d:", c)
    
    this.cond.compile(ctx)
    if !exprIsMtype(this.cond,ctx){
        internal.isTrue()
    }
    compile.CreateCmp()
    compile.writeln("    je  L.while.end.%d", c)

    compile.blockcreate(ctx)
    
    std.tail(ctx).po= c
    std.tail(ctx).end_str   = "L.while.end"
    std.tail(ctx).start_str = "L.while.begin"
    
    for(stmt : this.block.stmts){
        stmt.compile(ctx)
    }
    compile.blockdestroy(ctx)

    compile.writeln("    jmp L.while.begin.%d",c)
    compile.writeln("L.while.end.%d:", c)
}
WhileStmt::dead_compile(ctx)
{
    this.record()
    c = ast.incr_labelid()
    
    compile.writeln("L.while.begin.%d:", c)
    
    compile.blockcreate(ctx)
    
    std.tail(ctx).po= c
    std.tail(ctx).end_str   = "L.while.end"
    std.tail(ctx).start_str = "L.while.begin"
    
    for(stmt : this.block.stmts){
        stmt.compile(ctx)
    }
    compile.blockdestroy(ctx)

    compile.writeln("    jmp L.while.begin.%d",c)
    compile.writeln("L.while.end.%d:", c)
}
class IfCaseExpr : ast.Ast {
    cond
    block
    label endLabel
    func init(line,column){
        super.init(line,column)
    }
}
IfCaseExpr::toString(){
    str = "cond="
    str += this.cond.toString()
    str += ",exprs=["
    if this.block {
        for(e : this.block.stmts){
            str += e.toString()
            str += ","
        }
    }
    str += "])"
    return str
}
IfCaseExpr::compile(ctx){
    utils.debug("gen.IfCaseExpr::compile()")
    this.record()
    compile.writeln("%s:",this.label)
    if this.block {
        for(stmt : this.block.stmts){
            stmt.compile(ctx)
        } 
    }
    compile.writeln("   jmp %s", this.endLabel)
    return this
}
class IfStmt : ast.Ast {
    cases = [] 
    elseCase
    func init(line,column){
        super.init(line,column)
    }
}
IfStmt::toString() {
    str = ""
    for(cs : this.cases){
        str += cs.toString()
    }
    str += this.elseCase.toString()
    return str
}
IfStmt::compile(ctx){
    utils.debug("gen.IfStmt::compile()")
    this.record()
    mainPoint = ast.incr_labelid()
    endLabel = "L.if.end." + mainPoint
    
    for(cs : this.cases){
        cs.label  = "L.if.case." + ast.incr_labelid()
        cs.endLabel = endLabel
    }
    if this.elseCase {
        this.elseCase.label = "L.if.case." + ast.incr_labelid()
        this.elseCase.endLabel = endLabel
    }

    for(cs : this.cases){
        cs.cond.compile(ctx)
        if !exprIsMtype(cs.cond,ctx)
            internal.isTrue()
        compile.writeln("    cmp $1, %%rax")
        compile.writeln("    je  %s", cs.label)
    }
    
    if this.elseCase compile.writeln("   jmp %s", this.elseCase.label)
    
    compile.writeln("   jmp L.if.end.%d", mainPoint)
    
    compile.blockcreate(ctx)
    for(cs : this.cases){
        cs.compile(ctx)
    }
    if this.elseCase this.elseCase.compile(ctx)
    compile.blockdestroy(ctx)

    compile.writeln("L.if.end.%d:",mainPoint)
    return null
}
