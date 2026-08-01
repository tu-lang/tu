use string
use std
use fmt
use compiler.ast
use compiler.parser.scanner
use compiler.parser.package
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
                }
                s = p.pkg.getPackage(var.structpkg).getStruct(var.structname)
                if s == null expr.check(false,"gen await static struct not exist")
                asyncfn = s.resolveAsyncMember(fc.funcname)
                if asyncfn == null || asyncfn.fntype != ast.AsyncFunc {
                    expr.check(false,"gen await: func not async")
                }
                return asyncfn.asyncst
            }
        }
        parent = p.getStruct("", fc.package)
        if parent != null {
            asyncfn = parent.resolveAsyncMember(fc.funcname)
            if asyncfn != null && asyncfn.fntype == ast.AsyncFunc
                return asyncfn.asyncst
        }
        s = p.getStruct(fc.package,fc.funcname) 
        if s == null {
            expr.check(false,"await function not found when async gen")
        }
        return s
    }else if type(expr) == type(gen.MemberCallExpr) {
        mc = expr
        fc = mc.call
        if fc == null
            expr.check(false,"membercall await missing call expr")
        parent = null
        if mc.staticCall != null {
            parent = mc.staticCall
        }else if mc.obj != null {
            parent = p.pkg.getPackage(mc.obj.structpkg).getStruct(mc.obj.structname)
        }else if mc.tyassert != null {
            parent = mc.tyassert.getStruct()
        }else if curf.thisvar != null && curf.thisvar.structname != "" {
            parent = p.getStruct(curf.thisvar.structpkg, curf.thisvar.structname)
        }
        if parent == null
            expr.check(false,"gen await membercall without struct context")
        asyncfn = parent.resolveAsyncMember(mc.membername)
        if asyncfn == null || asyncfn.fntype != ast.AsyncFunc {
            expr.check(false,"gen await: func not async")
        }
        return asyncfn.asyncst
    }else{
        expr.check(false,"expr can't be await struct")
    }
}

AsyncBlock::isRuntimeFutureStruct(s){
    // Erased runtime.Future: not mem:async, poll via FutureCall / get_future_poll
    if s == null return false
    if s.name != "Future" return false
    if s.pkg == "runtime" return true
    if (s.pkg == "" || s.pkg == null) && this.root.curp != null &&
       this.root.curp.getpkgname() == "runtime" {
        return true
    }
    return false
}

// Sync callee return: runtime.Future or mem X: async leaf
AsyncBlock::awaitableFromReturnTypes(callee){
    if callee == null return null
    if callee.fntype == ast.AsyncFunc || callee.isasync() return null
    if std.len(callee.returnTypes) == 0 return null
    rt = callee.returnTypes[0]
    if rt == null || !rt.memType() return null
    // Bare return type resolves in callee's package (cross-pkg await)
    st = null
    if rt.pkg != null && rt.pkg != "" {
        st = package.getStruct(rt.pkg, rt.name)
    }else if callee.package != null {
        st = callee.package.getStruct(rt.name)
    }
    if st == null {
        st = package.getStruct(rt.pkg, rt.name)
    }
    if st == null return null
    if this.isRuntimeFutureStruct(st) || st.isasync
        return st
    return null
}

// Package-level sync fn returning awaitable; skip object / Type::method FunCall shape
AsyncBlock::pkgCallAwaitableLeaf(fc){
    if fc == null return null
    p = this.root.curp
    curf = this.root.fc

    if fc.package != null && fc.package != "" {
        var = ast.GP().getGlobalVar("", fc.package)
        if var == null {
            var = curf.FindLocalVar(fc.package)
        }
        if var != null return null
        parent = p.getStruct("", fc.package)
        if parent != null return null
    }

    pkgname = fc.package
    if pkgname != null && pkgname != "" && p.pkg.imports[pkgname] != null {
        pkgname = p.pkg.imports[pkgname]
    }
    if pkgname == null || pkgname == "" {
        pkgname = p.getpkgname()
    }
    if package.packages[pkgname] == null return null
    callee = package.packages[pkgname].getFunc(fc.funcname, false)
    return this.awaitableFromReturnTypes(callee)
}

// Type::method / obj.method sync factory returning awaitable leaf
AsyncBlock::memberCallAwaitableLeaf(mc){
    if mc == null return null
    p = this.root.curp
    curf = this.root.fc

    parent = null
    if mc.staticCall != null {
        parent = mc.staticCall
    }else if mc.obj != null {
        opkg = p.pkg.getPackage(mc.obj.structpkg)
        if opkg != null
            parent = opkg.getStruct(mc.obj.structname)
        if parent == null
            parent = package.getStruct(mc.obj.structpkg, mc.obj.structname)
    }else if mc.tyassert != null {
        parent = mc.tyassert.getStruct()
    }else if curf.thisvar != null && curf.thisvar.structname != "" {
        parent = p.getStruct(curf.thisvar.structpkg, curf.thisvar.structname)
    }
    if parent == null return null

    asyncfn = parent.resolveAsyncMember(mc.membername)
    if asyncfn != null && asyncfn.fntype == ast.AsyncFunc
        return null

    memfn = parent.getFunc(mc.membername)
    fromRet = this.awaitableFromReturnTypes(memfn)
    if fromRet != null return fromRet
    if parent.syncFactoryLeaves[mc.membername] != null
        return parent.syncFactoryLeaves[mc.membername]
    return null
}

AsyncBlock::genawait(stmt , recvs){
    if type(stmt) == type(gen.FunCallExpr) {
        fc = stmt
        // Instance sync factory: obj.method() as FunCall(package=obj, funcname=method)
        if fc.package != null && fc.package != "" {
            var = ast.GP().getGlobalVar("", fc.package)
            if var == null {
                var = this.root.fc.FindLocalVar(fc.package)
            }
            if var != null && var.structtype && var.structname != "" {
                parent = null
                opkg = this.root.curp.pkg.getPackage(var.structpkg)
                if opkg != null
                    parent = opkg.getStruct(var.structname)
                if parent == null
                    parent = package.getStruct(var.structpkg, var.structname)
                if parent != null {
                    asyncfn = parent.resolveAsyncMember(fc.funcname)
                    if asyncfn == null || asyncfn.fntype != ast.AsyncFunc {
                        memfn = parent.getFunc(fc.funcname)
                        leaf = this.awaitableFromReturnTypes(memfn)
                        if leaf == null && parent.syncFactoryLeaves[fc.funcname] != null
                            leaf = parent.syncFactoryLeaves[fc.funcname]
                        if leaf != null
                            return this.leafawait(fc, leaf, recvs)
                    }
                }
            }
        }
        leaf = this.pkgCallAwaitableLeaf(fc)
        if leaf != null {
            return this.leafawait(fc, leaf, recvs)
        }
        s = this.getstruct(stmt)
        if s == null {
            if fc.package != null && fc.package != "" {
                var = ast.GP().getGlobalVar("", fc.package)
                if var == null
                    var = this.root.fc.FindLocalVar(fc.package)
                if var != null && var.structtype && var.structname != "" {
                    stmt.check(false,
                        "member-async .await: async leaf not found for typed receiver "
                        + var.structpkg + "." + var.structname + "::" + fc.funcname)
                }
            }
            return this.dynawait(fc,recvs)
        }
        retvar = this.genawait2(s,fc,recvs,false)
        return retvar
    }else if type(stmt) == type(gen.AssignExpr) {
        ae = stmt
        if !gen.expressionHasAwait(ae.rhs) {
           ae.check(false,"right must be await expression") 
        }
        retvar = this.genawait(ae.rhs,recvs)
       ae.rhs = retvar
       this.push(ae)
       return ae.lhs
    }else if type(stmt) == type(gen.BinaryExpr) {
        be = stmt
        if be.lhs != null && gen.expressionHasAwait(be.lhs) {
            be.lhs = this.genawait(be.lhs,recvs)
        }
        if be.rhs != null && gen.expressionHasAwait(be.rhs) {
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
        if astruct == null {
            stmt.check(false,"not future var,can't be await")
        }
        awaitable = astruct.isasync || this.isRuntimeFutureStruct(astruct)
        stmt.check(awaitable,"not future var,can't be await")

        retvar  = this.genawait3(rv,astruct,call,recvs)
        return retvar
    }else if type(stmt) == type(gen.MemberCallExpr) {
        mc = stmt
        fc = mc.call
        if fc == null
            stmt.check(false,"membercall await missing call expr")
        syncLeaf = this.memberCallAwaitableLeaf(mc)
        if syncLeaf != null {
            // Assign whole MemberCallExpr: inner FunCall funcname is often empty
            return this.leafawait(mc, syncLeaf, recvs)
        }
        s = this.getstruct(stmt)
        return this.genawait2(s, fc, recvs, false)
    }else {
        stmt.check(false,"unknown await stmt type")
    }        
}

// Sync factory already returned awaitable: assign then poll (no genawait2 rebuild).
// rhs may be FunCallExpr or MemberCallExpr.
// Shared with genawait2: full_package + consumer import alias for cross-pkg NewStruct.
AsyncBlock::awaitLeafPkgAnnot(leaf){
    full = leaf.pkg
    if leaf.parser != null {
        g = leaf.parser.getpkgname()
        if g != null && g != "" {
            full = g
        }
    }
    cur = this.root.curp
    if cur != null && cur.pkg != null && full != null && full != "" {
        for alias, path : cur.pkg.imports {
            if path == full {
                return alias
            }
        }
    }
    return full
}

AsyncBlock::leafawait(rhs, leaf, recvs){
    if leaf == null {
        rhs.check(false, "leafawait missing leaf struct")
    }
    casevar = this.gencasevar()
    casevar.structname = leaf.name
    casevar.structpkg = this.awaitLeafPkgAnnot(leaf)

    assignExpr = new gen.AssignExpr(0, 0)
    assignExpr.opt = ast.ASSIGN
    assignExpr.lhs = casevar
    assignExpr.rhs = rhs
    this.push(assignExpr)

    call = new gen.FunCallExpr(rhs.line, rhs.column)
    if type(rhs) == type(gen.FunCallExpr) {
        call.p = rhs.p
    }else if type(rhs) == type(gen.MemberCallExpr) {
        if rhs.call != null
            call.p = rhs.call.p
    }
    call.args[] = casevar
    call.args[] = this.fc.ctxvar

    return this.genawait3(casevar, leaf, call, recvs)
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
    fc.is_pkgcall = true
    // args
    oldargs = fc.args
    newargs = []

    newargs[] = new gen.VarExpr(objname,0,0)
    fsig      = new gen.IntExpr(0,0)

    hk = utils.hash(callname)
    fsig.lit = fmt.sprintf("%d",hk)

    fsig.tyassert = new gen.TypeInfo(0,0)
    fsig.tyassert.base = ast.U64
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
    pkgannot = this.awaitLeafPkgAnnot(s)
    casevar.structpkg = pkgannot

    assignExpr = new gen.AssignExpr(0, 0)
    assignExpr.opt = ast.ASSIGN
    assignExpr.lhs = casevar
    newsvar = new gen.NewStructExpr(0,0)
    newsvar.init = new gen.StructInitExpr(0,0)
    newsvar.init.pkgname = pkgannot
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
        // Concrete async leaf: static ret slot; erased Future: dynamic like dynawait
        retvar = this.genretvar(s != null && s.isasync)
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
        if !gen.expressionHasAwait(ae.rhs) {
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