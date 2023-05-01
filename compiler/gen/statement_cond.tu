use ast
use std

class ForStmt : ast.Ast {
    func init(line,column){
        //TODO: closure call super(line,column)
        super.init(line,column)
    }
    init = null
    cond = null
    after = null
    block = null

    range = false
    key   = null
    value = null
    obj   = null
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
    utils.debugf("gen.ForExpr::rangeFor()")
    c = ast.incr_labelid()
    if this.obj == null 
        this.panic("statement: for(x,y : obj) obj should pass value. line:%d column:%d",this.line,this.column)
    
    this.obj.compile(ctx)
    compile.Push()
    
    // compile.writeln("   mov (%%rsp),%%rdi")
    internal.call("runtime_for_first",0)
    compile.Push()
    
    
    compile.writeln("%s.L.forr.begin.%d:",compile.currentParser.label(), c)
    
    compile.CreateCmp()
    compile.writeln("    je  %s.L.forr.end.%d",compile.currentParser.label(), c)

    
    if this.key != null{
        std.tail(ctx).createVar(this.key.varname,this.key)
        // compile.writeln("   mov 8(%%rsp),%%rdi")
        // compile.writeln("   mov (%%rsp),%%rsi")
        internal.call("runtime_for_get_key",0)
        compile.Push()

        compile.GenAddr(this.key.getVar(ctx,this.key))
        compile.Pop("%rdi")
        compile.writeln("   mov %%rdi,(%%rax)")
    }
    if this.value != null {
        std.tail(ctx).createVar(this.value.varname,this.value)
        // compile.writeln("   mov 8(%%rsp),%%rdi")
        // compile.writeln("   mov (%%rsp),%%rsi")
        internal.call("runtime_for_get_value",0)
        compile.Push()
        compile.GenAddr(this.value.getVar(ctx,this.value))
        compile.Pop("%rdi")
        compile.writeln("   mov %%rdi,(%%rax)")
    }

    compile.blockcreate(ctx)
    
    std.tail(ctx).point = c
    std.tail(ctx).end_str   = compile.currentParser.label() + ".L.forr.end"
    std.tail(ctx).start_str = compile.currentParser.label() + ".L.forr.begin"
    std.tail(ctx).continue_str = compile.currentParser.label() + ".L.for.continue"
    
    
    for(stmt : this.block.stmts){
        stmt.compile(ctx)
    }
    compile.blockdestroy(ctx)

    compile.writeln("%s.L.for.continue.%d:",compile.currentParser.label(),c)
    // compile.writeln("   mov 8(%%rsp),%%rdi")
    // compile.Pop("%rsi")
    internal.call("runtime_for_get_next",1)
    compile.Push()

    compile.writeln("    jmp %s.L.forr.begin.%d",compile.currentParser.label(),c)
    compile.writeln("%s.L.forr.end.%d:",compile.currentParser.label(), c)
    
    compile.writeln("   add $16,%%rsp")
    return null
}
ForStmt::triFor(ctx)
{
    utils.debugf("gen.ForExpr::triFor()")
    c = ast.incr_labelid()
    compile.blockcreate(ctx)
    this.init.compile(ctx)
    
    compile.writeln("%s.L.for.begin.%d:",compile.currentParser.label(), c)
    this.cond.compile(ctx)
    if !exprIsMtype(this.cond,ctx) {
        internal.isTrue()
    }
    compile.CreateCmp()
    compile.writeln("    je  %s.L.for.end.%d",compile.currentParser.label(), c)

    std.tail(ctx).point = c
    std.tail(ctx).end_str   = compile.currentParser.label() + ".L.for.end"
    std.tail(ctx).start_str = compile.currentParser.label() + ".L.for.begin"
    std.tail(ctx).continue_str = compile.currentParser.label() + ".L.for.continue"
    
    
    for(stmt : this.block.stmts){
        stmt.compile(ctx)
    }
    
    compile.writeln("%s.L.for.continue.%d:",compile.currentParser.label(),c)
    
    this.after.compile(ctx)
    compile.blockdestroy(ctx)

    compile.writeln("    jmp %s.L.for.begin.%d",compile.currentParser.label(),c)
    compile.writeln("%s.L.for.end.%d:",compile.currentParser.label(), c)

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
    utils.debugf("gen.WhileStmtExpr::compile()")
    if this.dead return this.dead_compile(ctx)
    this.record()
    c = ast.incr_labelid()
    
    compile.writeln("%s.L.while.begin.%d:", compile.currentParser.label(),c)
    
    this.cond.compile(ctx)
    if !exprIsMtype(this.cond,ctx){
        internal.isTrue()
    }
    compile.CreateCmp()
    compile.writeln("    je  %s.L.while.end.%d",compile.currentParser.label(), c)

    compile.blockcreate(ctx)
    
    std.tail(ctx).point = c
    std.tail(ctx).end_str   = compile.currentParser.label() + ".L.while.end"
    std.tail(ctx).start_str = compile.currentParser.label() + ".L.while.begin"
    
    for(stmt : this.block.stmts){
        stmt.compile(ctx)
    }
    compile.blockdestroy(ctx)

    compile.writeln("    jmp %s.L.while.begin.%d",compile.currentParser.label(),c)
    compile.writeln("%s.L.while.end.%d:",compile.currentParser.label(), c)
    return null
}
WhileStmt::dead_compile(ctx)
{
    utils.debugf("gen.WhileStmtExpr::dead_compile()")
    this.record()
    c = ast.incr_labelid()
    
    compile.writeln("%s.L.while.begin.%d:",compile.currentParser.label(), c)
    
    compile.blockcreate(ctx)
    
    std.tail(ctx).point = c
    std.tail(ctx).end_str   = compile.currentParser.label() + ".L.while.end"
    std.tail(ctx).start_str = compile.currentParser.label() + ".L.while.begin"
    
    for(stmt : this.block.stmts){
        stmt.compile(ctx)
    }
    compile.blockdestroy(ctx)

    compile.writeln("    jmp %s.L.while.begin.%d",compile.currentParser.label(),c)
    compile.writeln("%s.L.while.end.%d:", compile.currentParser.label(),c)
}
class IfCaseExpr : ast.Ast {
    cond
    block
    label = ""
    endLabel = ""
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
    endLabel = compile.currentParser.label() + ".L.if.end." + mainPoint
    
    for(cs : this.cases){
        cs.label  = compile.currentParser.label() + ".L.if.case." + ast.incr_labelid()
        cs.endLabel = endLabel
    }
    if this.elseCase {
        this.elseCase.label = compile.currentParser.label() + ".L.if.case." + ast.incr_labelid()
        this.elseCase.endLabel = endLabel
    }

    for(cs : this.cases){
        if(exprIsMtype(cs.cond,ctx) && type(cs.cond) != type(BinaryExpr)){
            be = new gen.BinaryExpr(cs.cond.line,cs.cond.column)
            be.lhs = cs.cond
            be.opt = ast.GT
            i = new gen.IntExpr(cs.cond.line,cs.cond.column)
            i.lit = "0"
            be.rhs = i
            cs.cond = be
        }
        cs.cond.compile(ctx)
        if !exprIsMtype(cs.cond,ctx)
            internal.isTrue()
        compile.writeln("    cmp $1, %%rax")
        compile.writeln("    je  %s", cs.label)
    }
    
    if this.elseCase compile.writeln("   jmp %s", this.elseCase.label)
    
    compile.writeln("   jmp %s.L.if.end.%d", compile.currentParser.label(),mainPoint)
    
    compile.blockcreate(ctx)
    for(cs : this.cases){
        cs.compile(ctx)
    }
    if this.elseCase this.elseCase.compile(ctx)
    compile.blockdestroy(ctx)

    compile.writeln("%s.L.if.end.%d:",compile.currentParser.label(),mainPoint)
    return null
}
