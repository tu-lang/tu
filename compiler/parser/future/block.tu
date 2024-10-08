use string
use std
use compiler.ast
use compiler.parser.scanner
use compiler.utils
use runtime
use compiler.gen

AsyncBlock::genstate(case1){
    assignExpr = new gen.AssignExpr(0, 0)
    assignExpr.opt = ast.ASSIGN
    assignExpr.lhs = this.gstatevar()
    state = new gen.IntExpr(0,0)
    state.lit = case1.id + ""
    assignExpr.rhs = state
    return assignExpr
}

AsyncBlock::genswitch(case1){
    stmt = new gen.GotoStmt("",0,0)
    stmt.case1 = case1
    return stmt
}

AsyncBlock::getstruct(expr){
    p = this.root.curp
    if type(expr) == type(gen.FunCallExpr) {
        fc = expr
        s = p.getStruct(fc.package,fc.funcname) 
        if s == null {
            expr.check(false,"await function not found")
        }
        return s
    }else{
        expr.check(false,"expr can't be await struct")
    }
}

AsyncBlock::genawait(stmt , recvs){
    if type(stmt) == type(gen.FunCallExpr) {
        fc = stmt
        s = this.getstruct(stmt)
        retvar = this.genawait2(s,fc,recvs,false)
        return retvar
    }else if type(stmt) == type(gen.AssignExpr) {
        ae = stmt
        if !ae.rhs.hasawait {
           ae.check(false,"right must be await expression") 
        }
        retvar = this.genawait(ae.rhs,recvs)
       ae.rhs = retvar
       this.push(ae)
       return ae.lhs
    }else if type(stmt) == type(gen.BinaryExpr) {
        be = stmt
        if be.lhs != null && be.lhs.hasawait {
            be.lhs = this.genawait(be.lhs,recvs)
        }
        if be.rhs != null && be.rhs.hasawait {
            be.rhs = this.genawait(be.rhs,recvs)
        }
       return be       
    }else if type(stmt) == type(gen.VarExpr) {
        rv = this.fc.FindLocalVar(stmt.varname)
        if rv == null {
            stmt.check(false,"await gen in var, var not exist")
        }
        astruct = this.root.curp.getStruct(rv.structpkg,rv.structname)
        call    = new gen.FunCallExpr(0,0)

        call.args[] = rv
        call.args[] = this.fc.ctx

        retvar  = this.genawait3(rv,astruct,call,recvs)
        return retvar
    }else {
        stmt.check(false,"unknown await stmt type")
    }        
}

AsyncBlock::genawait2(s , callargs , recvs, isstatic){
    casevar = this.gencasevar()
    casevar.structname = s.name 
    casevar.structpkg = s.pkg

    assignExpr = new gen.AssignExpr(0, 0)
    assignExpr.opt = ast.ASSIGN
    assignExpr.lhs = casevar
    newsvar = new gen.NewStructExpr(0,0)
    newsvar.init = new gen.StructInitExpr(0,0)
    newsvar.init.pkgname = s.pkg
    newsvar.init.name = s.name

    for i = 1 ; i < std.len(s.member) ; i += 1 {
        m = s.member[i]
        if i < std.len(callargs) {
            newsvar.init.fields[m.name] = callargs.args[i - 1]
        }else{
            newsvar.init.fields[m.name] = new gen.NullExpr(0,0)
        }
    }
    callargs.args = []
    callargs.args[] = this.fc.ctx

    assignExpr.rhs = newsvar
    this.push(assignExpr)

    prevcur = std.tail(this.queue)
    this.create()
    prevcur.blocks[] = this.genstate(std.tail(this.queue))
    prevcur.blocks[] = this.genswitch(std.tail(this.queue))

    pollassign  = null
    retvar = null
    if recvs != null {
        pollassign = this.genpollrecv2(casevar,recvs,callargs)
        retvar = null
    }else{
        retvar = this.genretvar(isstatic)
        pollassign = this.genpollrecv(
            casevar,retvar,callargs
        )
    }

    this.push(pollassign)

    pollif = this.genpollisready()
    this.push(pollif)
    
    return retvar
}
AsyncBlock::genawait3(sv, s, callargs, recvs){
    casevar = sv

    prevcur = std.tail(this.queue)
    this.create()
    prevcur.blocks[] = this.genstate(std.tail(this.queue))
    prevcur.blocks[] = this.genswitch(std.tail(this.queue))

    pollassign = null
    retvar = null
    if recvs != null {
        pollassign = this.genpollrecv2(casevar,recvs,callargs)
        retvar = null
    }else{
        retvar = this.genretvar(true)
        pollassign = this.genpollrecv(
            casevar,retvar,callargs
        )
    }

    this.push(pollassign)

    pollif = this.genpollisready()
    this.push(pollif)

    return retvar
}

AsyncBlock::genawaitresult(retvar , stmt){
    if type(stmt) == type(gen.FunCallExpr) {
        return retvar
    }else if type(stmt) == type(gen.AssignExpr) {
        ae = stmt
        if !ae.rhs.hasawait {
           ae.check(false,"right must be await expression") 
        }
       ae.rhs = retvar
       this.push(ae)
       return ae.lhs
    }else {
        utils.error(" unknown type")
    }
    return null
}

AsyncBlock::editstate( snum ){
    assignExpr = new gen.AssignExpr(0, 0)
    assignExpr.opt = ast.ASSIGN
    assignExpr.lhs = this.root.state
    state = new gen.IntExpr(0,0)
    state.lit = snum + ""
    assignExpr.rhs = state

    this.push( assignExpr)
}
AsyncBlock::genstate2( snum){
    assignExpr = new gen.AssignExpr(0, 0)
    assignExpr.opt = ast.ASSIGN
    assignExpr.lhs = this.root.state
    state = new gen.IntExpr(0,0)
    state.lit = snum + ""
    assignExpr.rhs = state
    return assignExpr
}
AsyncBlock::genpollstate(snum){
    assignExpr = new gen.AssignExpr(0, 0)
    assignExpr.opt = ast.ASSIGN
    assignExpr.lhs = this.root.pollstate
    state = new gen.IntExpr(0,0)
    state.lit = snum + ""
    assignExpr.rhs = state

    return assignExpr
}

AsyncBlock::genpollrecv(pollvar , retvar , callargs){

    mret = new gen.MultiAssignStmt(0,0)
    mret.opt = ast.ASSIGN
    mret.ls[] = this.gpollvar()
    mret.ls[] = retvar

    callargs.package = pollvar.varname
    callargs.funcname = "poll"

    mret.rs[] = callargs
    return mret 
}
AsyncBlock::genpollrecv2(pollvar,recvs, callargs){

    mret = recvs
    ls = mret.ls
    mret.ls = []
    mret.ls[] = this.gpollvar()
    std.merge(mret.ls,ls)

    callargs.package = pollvar.varname
    callargs.funcname = "poll"

    mret.rs[0] = callargs
    return mret 
}
AsyncBlock::genpollisready(){
    pollif = new gen.IfStmt(0,0)
    pollcase = new gen.IfCaseExpr(0,0)
    cmpexpr = new gen.BinaryExpr(0,0)
    cmpexpr.opt = ast.NE
    cmpexpr.lhs = this.root.pollstate
    readstate = new gen.IntExpr(0,0)
    readstate.lit = PollReady + ""
    cmpexpr.rhs = readstate

    pollcase.cond = cmpexpr
    ret = new gen.ReturnStmt(0,0)
    ret.ret[] = this.root.pollstate
    pollcase.block = ret

    pollif.cases[] = pollcase

    return pollif
}