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
    // Explicit AwaitExpr: chain call result / field / index / paren / await result
    if type(stmt) == type(gen.AwaitExpr) {
        return this.awaitExprPrim(stmt, recvs)
    }
    // Not an await site: a composite expression with nested awaits, lifted one by one
    if !gen.isAwaitSite(stmt) {
        if type(stmt) == type(gen.BinaryExpr) && recvs != null && std.len(recvs.ls) == 1 {
            // sum = a.await + b.await: sub-awaits land in temp slots, then assign the receiver
            be = this.lift(stmt)
            ae = new gen.AssignExpr(stmt.line, stmt.column)
            ae.opt = recvs.opt
            ae.lhs = recvs.ls[0]
            ae.rhs = be
            this.push(ae)
            return recvs.ls[0]
        }
        if recvs != null
            stmt.check(false,"await: unsupported multi-receiver await expression")
        return this.lift(stmt)
    }
    if type(stmt) == type(gen.FunCallExpr) {
        fc = stmt
        // Lift awaits in call args left-to-right first: f(g().await, 1).await
        this.liftChildren(fc)
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
        // Plain sync fn (not async, no awaitable return): await its result as a dynamic value
        if this.isPlainCallNotAsync(fc) {
            fc.hasawait = false
            return this.awaitValue(fc, recvs)
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
            // Dynamic receiver obj.m().await: evaluate as a plain dynamic call, then
            // await_value. A dynamic call to an async method already returns a Future
            // (dynfuturenew2); a sync method returns its result (leaf / Future). Both
            // are checked by await_value at run time - async-ness is only known then.
            fc.hasawait = false
            return this.awaitValue(fc, recvs)
        }
        retvar = this.genawait2(s,fc,recvs,true)
        return retvar
    }else if type(stmt) == type(gen.VarExpr) {
        // v.await / v.(T).await
        return this.awaitVarSite(stmt, recvs)
    }else if type(stmt) == type(gen.MemberCallExpr) {
        mc = stmt
        fc = mc.call
        if fc == null
            stmt.check(false,"membercall await missing call expr")
        // Lift awaits in call args first
        this.liftChildren(fc)
        syncLeaf = this.memberCallAwaitableLeaf(mc)
        if syncLeaf != null {
            // Assign whole MemberCallExpr: inner FunCall funcname is often empty
            return this.leafawait(mc, syncLeaf, recvs)
        }
        s = this.getstruct(stmt)
        return this.genawait2(s, fc, recvs, true)
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

// casevar already holds an erased runtime.Future: new state + poll + ready check
// (used by awaitValue).
AsyncBlock::futurepoll(casevar, p, line, column, recvs){
    pollcall = new gen.FunCallExpr(line,column)
    pollcall.p = p
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
        retvar = this.genretvarForLeaf(s)
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
        retvar = this.genretvarForLeaf(s)
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
// ---- .await in any expression position ----
// Async bodies suspend only at statement boundaries, so every await site in an
// expression is lifted left-to-right into a leading state: the site becomes a
// temp result slot fut.r.N and the rewritten expression goes back to its
// statement. Non-await operand order is unspecified; awaits run left-to-right.
// && / || with an await on the right get a child state entered only when the
// left value needs it. Dynamic values (class fields, indexes, chain call
// results, plain call results, await results) go through runtime.await_value.

// Resolves a mem struct by annotation: current parser mapping first, then globals.
AsyncBlock::resolveStructAnnot(pkg, name){
    if name == null || name == "" return null
    p = this.root.curp
    s = null
    if p != null && p.pkg != null {
        opkg = p.pkg.getPackage(pkg)
        if opkg != null
            s = opkg.getStruct(name)
        if s == null
            s = p.getStruct(pkg, name)
    }
    if s == null
        s = package.getStruct(pkg, name)
    return s
}

// Mem struct named by a type assert (TypeInfo.st may not be filled at parse time).
AsyncBlock::typeInfoStruct(ta){
    if ta == null || !ta.memType() return null
    if ta.st != null return ta.st
    return this.resolveStructAnnot(ta.pkg, ta.name)
}

// Mem struct of a member field; empty member pkg resolves relative to the parent.
AsyncBlock::memberStruct(parent, m){
    if m == null || !m.isstruct return null
    if m.structref != null return m.structref
    s = null
    if m.structpkg != null && m.structpkg != ""
        s = this.resolveStructAnnot(m.structpkg, m.structname)
    if s == null && parent != null
        s = package.getStruct(parent.pkg, m.structname)
    if s == null
        s = this.resolveStructAnnot("", m.structname)
    return s
}

AsyncBlock::isAwaitableStruct(st){
    return st != null && (st.isasync || this.isRuntimeFutureStruct(st))
}

// Plain (non-async, non-awaitable-return) call f().await: result awaited as a dynamic value.
AsyncBlock::isPlainCallNotAsync(fc){
    if fc == null return false
    p = this.root.curp
    curf = this.root.fc
    if fc.package != null && fc.package != "" {
        // obj.m() / Type::m() shapes belong to the member path
        if ast.GP().getGlobalVar("", fc.package) != null return false
        if curf.FindLocalVar(fc.package) != null return false
        if p.getStruct("", fc.package) != null return false
    }else{
        // Local closure variable f().await is not a plain call
        if curf.FindLocalVar(fc.funcname) != null return false
    }
    // Top-level async fn has a same-named leaf struct
    if p.getStruct(fc.package, fc.funcname) != null return false
    pkgname = fc.package
    if pkgname != null && pkgname != "" && p.pkg.imports[pkgname] != null
        pkgname = p.pkg.imports[pkgname]
    if pkgname == null || pkgname == ""
        pkgname = p.getpkgname()
    if package.packages[pkgname] == null return false
    callee = package.packages[pkgname].getFunc(fc.funcname, false)
    if callee == null return false
    if callee.fntype == ast.AsyncFunc || callee.isasync() return false
    return true
}

// Dynamic await: fut.c.N = runtime.await_value(E) (dies on null / non-future), then erased poll.
AsyncBlock::awaitValue(e, recvs){
    casevar = this.gencasevar()
    casevar.structname = "Future"
    casevar.structpkg = "runtime"

    call = new gen.FunCallExpr(e.line, e.column)
    call.p = this.root.curp
    call.package = "runtime"
    call.funcname = "await_value"
    call.is_pkgcall = true
    call.awaitvalue = true
    call.args[] = e

    assignExpr = new gen.AssignExpr(e.line, e.column)
    assignExpr.opt = ast.ASSIGN
    assignExpr.lhs = casevar
    assignExpr.rhs = call
    this.push(assignExpr)

    return this.futurepoll(casevar, call.p, e.line, e.column, recvs)
}

// Await on a variable: assert / mem annotation → static leaf poll; dynamic → runtime.await_value.
AsyncBlock::awaitVarSite(v, recvs){
    // v.(T).await: leaf from the asserted type; assign the asserted value then poll
    if v.tyassert != null {
        st = this.typeInfoStruct(v.tyassert)
        v.check(this.isAwaitableStruct(st), "await: operand is not awaitable")
        v.hasawait = false
        return this.leafawait(v, st, recvs)
    }
    rv = this.fc.FindLocalVar(v.varname)
    if rv == null
        rv = ast.GP().getGlobalVar(v.package, v.varname)
    if rv == null
        v.check(false,"await gen in var, var not exist")

    // Untyped dynamic variable: checked at runtime
    if !rv.structtype {
        return this.awaitValue(rv, recvs)
    }
    // Native scalars (i32 etc.) can't be awaited
    if rv.structname == null || rv.structname == "" {
        v.check(false,"await: operand is not awaitable")
    }
    astruct = this.resolveStructAnnot(rv.structpkg, rv.structname)
    v.check(this.isAwaitableStruct(astruct),"await: operand is not awaitable")
    call = new gen.FunCallExpr(0,0)
    call.args[] = rv
    call.args[] = this.fc.ctxvar
    return this.genawait3(rv,astruct,call,recvs)
}

// Resolves the awaitable leaf of a static mem chain (this.in2.seven() / v.a.b /
// chain-end .(T)). Returns [leaf, asynccall]: asynccall is set when the chain
// ends in an async member (receiver first in args, built via genawait2);
// otherwise the caller assigns the whole chain to casevar and polls.
// Unresolvable (incl. dynamic chains) yields [null, null].
AsyncBlock::chainStaticLeaf(ch){
    none = [null, null]
    // Chain-end assert x.a.(T).await: the asserted type is the leaf
    if ch.tyassert != null {
        st = this.typeInfoStruct(ch.tyassert)
        if this.isAwaitableStruct(st) return [st, null]
        return none
    }
    n = std.len(ch.fields)
    if n == 0 return none
    first = ch.fields[0]
    // Single-field chains only accept a mem field itself (this.leaf / g.leaf)
    if n < 2 && type(first) != type(gen.StructMemberExpr) return none

    // 1. Head must be static mem: StructMemberExpr or a mem-annotated local
    cur = null
    if type(first) == type(gen.StructMemberExpr) {
        if first.var == null return none
        owner = null
        if first.tyassert != null
            owner = this.typeInfoStruct(first.tyassert)
        else
            owner = this.resolveStructAnnot(first.var.structpkg, first.var.structname)
        if owner == null return none
        cur = this.memberStruct(owner, owner.getMember(first.member))
    }else if type(first) == type(gen.VarExpr) {
        rv = this.fc.FindLocalVar(first.varname)
        if rv == null || !rv.structtype || rv.structname == null || rv.structname == "" return none
        cur = this.resolveStructAnnot(rv.structpkg, rv.structname)
    }
    if cur == null return none
    // this.leaf.await: the field type itself is the leaf
    if n == 1 {
        if this.isAwaitableStruct(cur) return [cur, null]
        return none
    }

    // 2. Middle nodes must be field accesses, drilling into mem field types
    for i = 1; i + 1 < n; i += 1 {
        f = ch.fields[i]
        if type(f) != type(gen.MemberExpr) return none
        if f.tyassert != null
            cur = this.typeInfoStruct(f.tyassert)
        else
            cur = this.memberStruct(cur, cur.getMember(f.membername))
        if cur == null return none
    }

    // 3. Tail: async member / sync factory / awaitable field
    last = ch.fields[n - 1]
    if type(last) == type(gen.MemberCallExpr) {
        if last.tyassert != null return none
        call = last.call
        if call == null return none
        asyncfn = cur.resolveAsyncMember(last.membername)
        if asyncfn != null && asyncfn.fntype == ast.AsyncFunc && asyncfn.asyncst != null {
            // Receiver = chain without its tail, first in args (same shape as obj.m().await)
            recv = null
            if n == 2 {
                recv = ch.fields[0]
            }else{
                prefix = new gen.ChainExpr(ch.line, ch.column)
                for i = 0; i + 1 < n; i += 1 {
                    prefix.fields[] = ch.fields[i]
                }
                recv = prefix
            }
            ac = new gen.FunCallExpr(call.line, call.column)
            ac.p = call.p
            ac.funcname = last.membername
            ac.args[] = recv
            for a : call.args {
                ac.args[] = a
            }
            return [asyncfn.asyncst, ac]
        }
        memfn = cur.getFunc(last.membername)
        leaf = this.awaitableFromReturnTypes(memfn)
        if leaf == null && cur.syncFactoryLeaves[last.membername] != null
            leaf = cur.syncFactoryLeaves[last.membername]
        return [leaf, null]
    }
    if type(last) == type(gen.MemberExpr) {
        st = null
        if last.tyassert != null
            st = this.typeInfoStruct(last.tyassert)
        else
            st = this.memberStruct(cur, cur.getMember(last.membername))
        if this.isAwaitableStruct(st) return [st, null]
    }
    return none
}

AsyncBlock::awaitExprPrim(aw, recvs){
    e = aw.expr
    // 1. Parenthesized bare call / variable: same as a direct .await
    if type(e) == type(gen.FunCallExpr) && !e.hasawait {
        e.hasawait = true
        return this.genawait(e, recvs)
    }
    if type(e) == type(gen.MemberCallExpr) {
        if e.call != null && !e.call.hasawait {
            e.call.hasawait = true
            e.hasawait = true
            return this.genawait(e, recvs)
        }
    }
    if type(e) == type(gen.VarExpr) && !e.hasawait {
        return this.awaitVarSite(e, recvs)
    }
    // 2a. Single mem field this.leaf.await (collapsed to StructMemberExpr)
    if type(e) == type(gen.StructMemberExpr) {
        ch = new gen.ChainExpr(e.line, e.column)
        ch.fields[] = e
        res = this.chainStaticLeaf(ch)
        if res[0] != null
            return this.leafawait(e, res[0], recvs)
    }
    // 2. Static mem chain: resolve the leaf and poll statically
    if type(e) == type(gen.ChainExpr) {
        // Lift in-chain awaits first (a head await slot may carry a mem annotation)
        this.liftChildren(e)
        res = this.chainStaticLeaf(e)
        if res[0] != null {
            if res[1] != null
                return this.genawait2(res[0], res[1], recvs, true)
            return this.leafawait(e, res[0], recvs)
        }
    }
    // 3. Otherwise lift the operand's own awaits, then await the resulting value
    val = this.lift(e)
    if type(val) == type(gen.VarExpr) {
        return this.awaitVarSite(val, recvs)
    }
    return this.awaitValue(val, recvs)
}

// Lifts new T{...} inits in struct member order (map order is not source order).
AsyncBlock::liftStructInit(init){
    if init == null return null
    s = this.resolveStructAnnot(init.pkgname, init.name)
    if s != null {
        for m : s.member {
            if init.fields[m.name] != null
                init.fields[m.name] = this.lift(init.fields[m.name])
        }
    }
    for k, v : init.fields {
        if gen.exprContainsAwait(v)
            init.fields[k] = this.lift(v)
    }
}

AsyncBlock::liftList(arr){
    for i = 0; i < std.len(arr); i += 1 {
        arr[i] = this.lift(arr[i])
    }
}

// Lifts e's direct children in place: call args, literal elements, index,
// new args / inits, binary sides, chain fields, assignment sides.
AsyncBlock::liftChildren(e){
    if e == null return null
    t = type(e)
    if t == type(gen.FunCallExpr) {
        this.liftList(e.args)
    }else if t == type(gen.MemberCallExpr) {
        this.liftChildren(e.call)
    }else if t == type(gen.ChainExpr) {
        // Head may be a whole await site (f().await.x / x.await[0]); later
        // fields only lift their args / indexes
        e.fields[0] = this.lift(e.fields[0])
        for i = 1; i < std.len(e.fields); i += 1 {
            f = e.fields[i]
            if gen.isAwaitSite(f)
                f.check(false,"await: unsupported .await position inside chain")
            this.liftChildren(f)
        }
    }else if t == type(gen.BinaryExpr) {
        e.lhs = this.lift(e.lhs)
        if e.rhs != null e.rhs = this.lift(e.rhs)
    }else if t == type(gen.AssignExpr) {
        // Lvalue: only lift its index / chain children, never into a temp
        if type(e.lhs) != type(gen.VarExpr)
            this.liftChildren(e.lhs)
        e.rhs = this.lift(e.rhs)
    }else if t == type(gen.IndexExpr) {
        if e.index != null e.index = this.lift(e.index)
    }else if t == type(gen.ArrayExpr) {
        this.liftList(e.lit)
    }else if t == type(gen.MapExpr) {
        this.liftList(e.lit)
    }else if t == type(gen.KVExpr) {
        e.key = this.lift(e.key)
        e.value = this.lift(e.value)
    }else if t == type(gen.NewClassExpr) {
        this.liftList(e.args)
    }else if t == type(gen.NewStructExpr) {
        this.liftStructInit(e.init)
    }else if t == type(gen.StructInitExpr) {
        this.liftStructInit(e)
    }else if t == type(gen.BuiltinFuncExpr) {
        e.expr = this.lift(e.expr)
    }else if t == type(gen.AddrExpr) {
        e.expr = this.lift(e.expr)
    }else if t == type(gen.DelRefExpr) {
        e.expr = this.lift(e.expr)
    }else if gen.exprContainsAwait(e) {
        e.check(false,"await: unsupported expression containing .await")
    }
}

// Lifts every await site in e left-to-right; returns the rewritten expression
// (e unchanged when it holds no await).
AsyncBlock::lift(e){
    if e == null || !gen.exprContainsAwait(e) return e
    if type(e) == type(gen.AwaitExpr)
        return this.awaitExprPrim(e, null)
    if gen.isAwaitSite(e)
        return this.genawait(e, null)
    if type(e) == type(gen.BinaryExpr) {
        if (e.opt == ast.LOGAND || e.opt == ast.LOGOR) && gen.exprContainsAwait(e.rhs)
            return this.liftLogical(e)
    }
    if type(e) == type(gen.AssignExpr) {
        // Assignment as a sub-expression / condition (if (a = f().await)):
        // hoist the assignment, the expression value is the lvalue
        this.liftChildren(e)
        this.push(e)
        return e.lhs
    }
    this.liftChildren(e)
    if type(e) == type(gen.ChainExpr) {
        // x.await.(T): after lifting only the slot + chain-end assert remain.
        // Collapse to a VarExpr carrying the assert (same shape as a parse-time
        // single-var assert); a slot-headed ChainExpr would be treated as dynamic.
        if std.len(e.fields) == 1 && e.tyassert != null {
            slot = e.fields[0]
            if type(slot) == type(gen.VarExpr) && slot.tyassert == null {
                ve = new gen.VarExpr(slot.varname, e.line, e.column)
                ve.tyassert = e.tyassert
                return ve
            }
        }
    }
    return e
}

// && / || whose rhs awaits: the rhs runs in a child state entered only when
// the left value requires it, keeping short-circuit semantics.
AsyncBlock::liftLogical(be){
    // c = L'
    lv = this.lift(be.lhs)
    c = new gen.VarExpr("fut.l." + this.get_label_id(), be.line, be.column)
    c.size = 8
    c.inferFromInit = true
    // The parent's final expr may compile before this slot's child state, so
    // type it from lv rather than from the first assignment.
    c.inferExpr = lv
    this.fc.InsertLocalVar(-1, c)
    ca = new gen.AssignExpr(be.line, be.column)
    ca.opt = ast.ASSIGN
    ca.lhs = c
    ca.rhs = lv
    this.push(ca)

    endid = this.gen_end_label()
    child = new AsyncBlock(this.fc, this.root)
    rv = child.lift(be.rhs)
    child.pushendstate(endid)
    this.merge(child)
    entry = child.queue[0]

    jump = new gen.BlockStmt()
    jump.stmts[] = this.genstate(entry)
    jump.stmts[] = this.genswitch(entry)

    ifs = new gen.IfStmt(0,0)
    ifc = new gen.IfCaseExpr(0,0)
    ifc.cond = c
    if be.opt == ast.LOGAND {
        // rhs needed only when c is true
        ifc.block = jump
    }else{
        // rhs needed only when c is false
        ifc.block = new gen.BlockStmt()
        efc = new gen.IfCaseExpr(0,0)
        efc.block = jump
        ifs.elseCase = efc
    }
    ifs.cases[] = ifc
    this.push(ifs)
    this.push(new gen.LabelExpr(endid,0,0))

    // Keep the original op: rhs is skipped when c short-circuits, else already computed
    be.lhs = c
    be.rhs = rv
    be.hasawait = false
    return be
}
