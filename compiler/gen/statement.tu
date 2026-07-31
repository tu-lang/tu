use compiler.ast
use compiler.compile
use compiler.parser.package
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

// True when expr is a call form eligible for multi-return forwarding.
// ChainExpr only counts when the last field is a call (not a field access).
func return_expr_looks_like_call(e){
    if e == null return false
    if type(e) == type(FunCallExpr) return true
    if type(e) == type(MemberCallExpr) return true
    if type(e) == type(ChainExpr) {
        ch = e
        if std.len(ch.fields) == 0 return false
        last = std.tail(ch.fields)
        if type(last) == type(FunCallExpr) return true
        if type(last) == type(MemberCallExpr) return true
        return false
    }
    return false
}

ReturnStmt::exprCast(ctx , expr, i){
    fc = ast.GF()
    defineType = null
    if std.len(fc.returnTypes) >= (i + 1) {
        defineType = fc.returnTypes[i]
    }
    if defineType != null {
        op = new OperatorHelper()
        op.ltoken = defineType.base
        op.lstruct = null
        op.ctx    = ctx
        if defineType.memType() {
            // mem heap pointer null is 0; not runtime_internal_null (breaks == null)
            if type(expr) == type(NullExpr) {
                compile.writeln("    mov $0, %%rax")
                return defineType
            }
            var = new VarExpr(defineType.name,0,0)
            var.structpkg = defineType.pkg
            var.structname = defineType.name
            op.apiCompile(var,expr)
            return null
        }
        op.staticCompile(expr)
        // if !op.isbase && !defineType.pointer && defineType.base != ast.I64 && defineType.base != ast.U64 {
            // expr.check(false,"cast may loss data")
        // }
        compile.Cast(op.rtoken,defineType.dstCastType())
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
    if fType != null && (fType.baseType() || fType.pointer) {
        ty = fType.abiToken()
    }
    compile.writeln(" mov %d(%%rbp) , %%rdi",stackpointer)
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
    // Mother: size >= (i+1) ⇔ len > i (0-based index i needs at least i+1 entries)
    if std.len(fc.returnTypes) > i {
        defineType = fc.returnTypes[i]
    }

    if i == 0 {
        if defineType != null{
            compile.writeln(" mov $0 , %%rax")
            if defineType.baseType() || defineType.pointer {
                compile.Cast(ast.I64,defineType.dstCastType())
            }
        }else if ast.cfg_static()
                compile.writeln(" mov $0 , %%rax")
        else compile.writeln("    lea runtime_internal_null(%%rip), %%rax")
        return null
    }

    cur = i - 1
    stackpointer = fc.ret_stack
    compile.writeln(" mov %d(%%rbp) , %%rdi",stackpointer)
    if defineType != null {
        // pointer defaults to full-width zero; do not Cast to pointee I8
        compile.writeln(" mov $0 , %%rax")
        if defineType.pointer {
            compile.writeln(" movq $0 , %d(%%rdi)",cur)
        }else if defineType.baseType() {
            compile.Cast(ast.I64,defineType.base)
            if ast.isfloattk(defineType.base)
                compile.PushfDst(defineType.base,"%rdi",cur)
            else 
                compile.writeln(" movq $0 , %d(%%rdi)",cur)
        }else{
            compile.writeln(" movq $0 , %d(%%rdi)",cur)
        }
    }else if ast.cfg_static() {
        compile.writeln(" movq $0 , %d(%%rdi)",cur)
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

    // return callee(): single multi-return call forwards as a group,
    // same as a,b = callee(); return a,b. Old path with ret.size()==1
    // filled extra slots via genDefault(0) and silently dropped values.
    if std.len(this.ret) == 1 && return_expr_looks_like_call(this.ret[0]) {
        compiled = this.ret[0].compile(ctx, false)
        fce = null
        if compiled != null && type(compiled) == type(FunCallExpr)
            fce = compiled

        // Dynamic ObjCall: multi-return on dyn ret stack (defaultfunc.mcount is wrong).
        if fce != null && fce.is_dyn {
            if fc.mcount > 1 {
                compile.Push()
                for i = fc.mcount - 1 ; i >= 0 ; i -= 1 {
                    spe = new StackPosExpr(this.line, this.column)
                    spe.isdyn = true
                    spe.cur = i + 1
                    spe.pos = 0
                    spe.compile(ctx, true)
                    if i == 0
                        continue
                    cur = i - 1
                    compile.writeln(" mov %d(%%rbp) , %%rdi", stackpointer)
                    compile.writeln(" mov %%rax , %d(%%rdi)", cur * 8)
                }
                compile.Pop("%rdi")
            }
            fce.dynfreeret()
            return null
        }

        if fce != null && fce.fcs != null && fce.fcs.mcount > 1 {
            callee = fce.fcs
            // Match MultiAssignStmt::assign: push rax first return, then StackPosExpr.
            ty = ast.I64
            if std.len(fc.returnTypes) > 0 {
                ti = fc.returnTypes[0]
                if ti.baseType() || ti.pointer
                    ty = ti.abiToken()
            }else if std.len(callee.returnTypes) > 0 {
                ti = callee.returnTypes[0]
                if ti.baseType() || ti.pointer
                    ty = ti.abiToken()
            }
            if ast.isfloattk(ty)
                compile.Pushf(ty)
            else
                compile.Push()

            for i = fc.mcount - 1 ; i >= 0 ; i -= 1 {
                if (i + 1) > callee.mcount {
                    this.genDefault(ctx, i)
                    continue
                }
                spe = new StackPosExpr(this.line, this.column)
                spe.total = callee.mcount
                spe.cur = i + 1
                spe.pos = 0
                spe.ismem = true
                spe.dstType = ast.I64
                if std.len(fc.returnTypes) > i {
                    rt = fc.returnTypes[i]
                    if rt.pointer || rt.baseType()
                        spe.dstType = rt.abiToken()
                    else {
                        spe.dstType = ast.I64
                        spe.st = package.getStruct(rt.pkg, rt.name)
                    }
                }else if std.len(callee.returnTypes) > i {
                    rt = callee.returnTypes[i]
                    if rt.pointer || rt.baseType()
                        spe.dstType = rt.abiToken()
                }
                spe.compile(ctx, true)
                if i == 0 {
                    // First return stays in rax
                    continue
                }
                cur = i - 1
                compile.writeln(" mov %d(%%rbp) , %%rdi", stackpointer)
                if ast.isfloattk(spe.dstType)
                    compile.PushfDst(spe.dstType, "%rdi", cur * 8)
                else
                    compile.writeln(" mov %%rax , %d(%%rdi)", cur * 8)
            }
            fce.freeret()
            return null
        }

        // Already compile(load=false): single-return result in rax; fill other slots.
        // genDefault clobbers rax — push first return, then restore.
        firstTy = ast.I64
        if std.len(fc.returnTypes) > 0 {
            defineType = fc.returnTypes[0]
            if defineType != null && (defineType.baseType() || defineType.pointer)
                firstTy = defineType.abiToken()
        }
        if ast.isfloattk(firstTy)
            compile.Pushf(firstTy)
        else
            compile.Push()
        for i = fc.mcount - 1 ; i >= 1 ; i -= 1
            this.genDefault(ctx, i)
        if ast.isfloattk(firstTy)
            compile.Popf(firstTy)
        else
            compile.Pop("%rax")
        if std.len(fc.returnTypes) > 0 {
            defineType = fc.returnTypes[0]
            if defineType != null && (defineType.baseType() || defineType.pointer)
                compile.Cast(ast.I64, defineType.dstCastType())
        }
        return null
    }

    // Pad missing / drop extras relative to declared mcount
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
        if std.len(fc.returnTypes) != 0 {
            ti = fc.returnTypes[0]
            if ti.baseType() || ti.pointer
                ty = ti.abiToken()
        }
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

        rexpr.dstType = lexpr.getType(ctx)
        if std.len(fc.returnTypes) > i {
            rt = fc.returnTypes[i]
            if rt.pointer || rt.baseType()
                rexpr.dstType = rt.abiToken()
            else{
                rexpr.dstType = ast.I64
                rexpr.st = package.getStruct(rt.pkg,rt.name)
            }
        }

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