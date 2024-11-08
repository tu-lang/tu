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
    p    = this.root.curp
    curf = this.root.fc
    if type(expr) == type(gen.FunCallExpr) {
        fc = expr
        if fc.package != null && fc.package != "" {
            var = ast.GP().getGlobalVar("",fc.package)
            if var == null {
                var = curf.FindLocalVar(fc.package)
            }
            if var != null {
                if !var.structtype || var.structname == "" {
                    return null
                    expr.check(false,"await function only support for struct member")
                }
                s = p.pkg.getPackage(var.structpkg).getStruct(var.structname)
                if s == null expr.check(false,"gen await static struct not exist")
                asyncfn = s.getFunc(fc.funcname)
                if asyncfn == null || asyncfn.fntype != ast.AsyncFunc {
                    expr.check(false,"gen await: func not async")
                }

                return asyncfn.asyncst
            }
        }

        s = p.getStruct(fc.package,fc.funcname) 
        if s == null {
            expr.check(false,"await function not found when async gen")
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
        if s == null {
            return this.dynawait(fc,recvs)
        }
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
        call.args[] = this.fc.ctxvar
        stmt.check(astruct.isasync,"not future var,can't be await")

        retvar  = this.genawait3(rv,astruct,call,recvs)
        return retvar
    }else {
        stmt.check(false,"unknown await stmt type")
    }        
}

AsyncBlock::dynawait(fc , recvs){
    casevar = this.gencasevar()
    casevar.structname = "Future" 
    casevar.structpkg = "runtime"

    //assign expression
    assignExpr = new gen.AssignExpr(0, 0)
    assignExpr.opt = ast.ASSIGN
    assignExpr.lhs = casevar
    objname = fc.package
    callname = fc.funcname
    fc.package = "runtime"
    fc.funcname = "dynfuturenew"
    // args
    oldargs = fc.args
    newargs = []

    newargs[] = new gen.VarExpr(objname,0,0)
    fsig      = new gen.IntExpr(0,0)

    hk = utils.hash(callname)
    fsig.lit = fmt.sprintf("%d",hk)

    fsig.tyassert = new gen.TypeAssertExpr(0,0)
    newargs[] = fsig
    //merge
    std.merge(newargs,oldargs)
    fc.args = newargs

    assignExpr.rhs = fc
    this.push(assignExpr)

    pollcall = new gen.FunCallExpr(fc.line,fc.column)
    pollcall.p = fc.p
    pollcall.package = casevar.varname
    pollcall.funcname = "poll"
    pollcall.args[] = casevar
    pollcall.args[] = this.fc.ctxvar

    prevcur = std.tail(this.queue)
    this.create()
    prevcur.blocks[] = this.genstate(
        std.tail(this.queue)
    )
    prevcur.blocks[] = this.genswitch(
        std.tail(this.queue)
    )
    pollassign = null 
    retvar = null
    if recvs != null {
        pollassign = this.genpollrecv2(casevar,recvs,pollcall)
        retvar = null//CONSIDER: mayb multiassign return a value too?
    }else{
        retvar = this.genretvar(false)
        pollassign = this.genpollrecv(
            casevar,retvar,pollcall
        )
    }

    this.push(pollassign)

    pollif = this.genpollisready()
    this.push(pollif)
    
    return retvar
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
        if i <= std.len(callargs.args) {
            newsvar.init.fields[m.name] = callargs.args[i - 1]
        }else{
            newsvar.init.fields[m.name] = new gen.NullExpr(0,0)
        }
    }
    callargs.args = []
    callargs.args[] = this.fc.ctxvar

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
    callargs.asyncgen = true

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
    callargs.asyncgen = true

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