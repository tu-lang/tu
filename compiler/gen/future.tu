// True when expr contains .await, including MemberCallExpr wrapping inner FunCallExpr.
// Also: propagate untyped locals from RHS mem/leaf/Future for static member-async await.
use compiler.ast
use compiler.compile
use compiler.parser.package
use std

func expressionHasAwait(e){
    if e == null return false
    if e.hasawait return true
    if type(e) == type(MemberCallExpr) {
        mc = e
        return mc.call != null && mc.call.hasawait
    }
    return false
}

func structFromTypeInfo(rt, callee){
    if rt == null || !rt.memType()
        return null
    if rt.pkg != ""
        return package.getStruct(rt.pkg, rt.name)
    if callee != null && callee.package != null
        return callee.package.getStruct(rt.name)
    return null
}

func structFromCalleeReturn(f){
    if f == null return null
    if f.fntype == ast.AsyncFunc {
        if f.asyncst != null
            return f.asyncst
    }
    if std.len(f.returnTypes) == 0
        return null
    return structFromTypeInfo(f.returnTypes[0], f)
}

func pkgAnnotForConsumer(st, cur){
    full = st.pkg
    if st.parser != null {
        g = st.parser.getpkgname()
        if g != ""
            full = g
    }
    if cur != null && cur.pkg != null && full != "" {
        for alias, path : cur.pkg.imports {
            if path == full
                return alias
        }
    }
    return full
}

func annotateVarWithStruct(v, st){
    if v == null || st == null
        return null
    if v.structtype && v.structname != ""
        return null

    cur = null
    if compile.currentFunc != null
        cur = compile.currentFunc.parser
    pkgannot = pkgAnnotForConsumer(st, cur)
    v.structtype = true
    v.structname = st.name
    v.structpkg = pkgannot
    v.type = ast.U64
    v.size = 8
    v.isunsigned = true

    fc = compile.currentFunc
    if fc == null
        return null
    canon = fc.FindLocalVar(v.varname)
    if canon != null && canon != v {
        if !canon.structtype || canon.structname == "" {
            canon.structtype = true
            canon.structname = st.name
            canon.structpkg = pkgannot
            canon.type = ast.U64
            canon.size = 8
            canon.isunsigned = true
        }
    }
}

func parentFromReceiverVar(recv, p){
    if recv == null || !recv.structtype || recv.structname == ""
        return null
    parent = null
    if p != null && p.pkg != null {
        opkg = p.pkg.getPackage(recv.structpkg)
        if opkg != null
            parent = opkg.getStruct(recv.structname)
    }
    if parent == null
        parent = package.getStruct(recv.structpkg, recv.structname)
    return parent
}

func structFromMemberOnParent(parent, membername){
    if parent == null return null
    asyncfn = parent.resolveAsyncMember(membername)
    if asyncfn != null && asyncfn.fntype == ast.AsyncFunc {
        if asyncfn.asyncst != null
            return asyncfn.asyncst
    }
    memfn = parent.getFunc(membername)
    fromRet = structFromCalleeReturn(memfn)
    if fromRet != null
        return fromRet
    if parent.syncFactoryLeaves[membername] != null
        return parent.syncFactoryLeaves[membername]
    return null
}

func structFromFunCall(fc){
    if fc == null return null
    curf = compile.currentFunc
    if curf == null return null
    p = curf.parser
    if p == null return null

    if fc.package != null && fc.package != "" {
        recv = ast.GP().getGlobalVar("", fc.package)
        if recv == null
            recv = curf.FindLocalVar(fc.package)
        if recv != null {
            parent = parentFromReceiverVar(recv, p)
            return structFromMemberOnParent(parent, fc.funcname)
        }
        parent = p.getStruct("", fc.package)
        if parent != null
            return structFromMemberOnParent(parent, fc.funcname)
    }

    pkgname = fc.package
    if pkgname != null && pkgname != "" && p.pkg != null && p.pkg.imports[pkgname] != null
        pkgname = p.pkg.imports[pkgname]
    if pkgname == null || pkgname == ""
        pkgname = p.getpkgname()
    if package.packages[pkgname] == null
        return null
    callee = package.packages[pkgname].getFunc(fc.funcname, false)
    return structFromCalleeReturn(callee)
}

func structFromMemberCall(mc){
    if mc == null return null
    curf = compile.currentFunc
    if curf == null return null
    p = curf.parser
    parent = null
    if mc.staticCall != null {
        parent = mc.staticCall
    } else if mc.obj != null {
        parent = parentFromReceiverVar(mc.obj, p)
    } else if mc.tyassert != null {
        parent = mc.tyassert.getStruct()
    } else if curf.thisvar != null && curf.thisvar.structname != "" {
        parent = p.getStruct(curf.thisvar.structpkg, curf.thisvar.structname)
    }
    return structFromMemberOnParent(parent, mc.membername)
}

func memStructFromRhs(rhs){
    if rhs == null return null
    if type(rhs) == type(FunCallExpr)
        return structFromFunCall(rhs)
    if type(rhs) == type(MemberCallExpr)
        return structFromMemberCall(rhs)
    if type(rhs) == type(NewStructExpr) {
        ns = rhs
        if ns.init == null
            return null
        if ns.init.pkgname == null || ns.init.pkgname == "" {
            if compile.currentFunc == null
                return null
            p = compile.currentFunc.parser
            if p == null || p.pkg == null
                return null
            return p.pkg.getStruct(ns.init.name)
        }
        return package.getStruct(ns.init.pkgname, ns.init.name)
    }
    return null
}

// Untyped local picks up mem/leaf/Future from RHS factory or async call.
func propagateVarMemTypeFromRhs(lhs, rhs){
    if lhs == null || rhs == null
        return null
    if compile.currentFunc == null
        return null
    if expressionHasAwait(rhs)
        return null
    st = memStructFromRhs(rhs)
    if st != null
        annotateVarWithStruct(lhs, st)
}

MemberCallExpr::checkawait(){
    if this.call != null && this.call.hasawait {
        this.hasawait = true
    }
}

IfStmt::checkawait(){
    for it : this.cases {
        if it.cond.hasawait {
            this.hasawait = true
            break
        }
        if it.block.hasawait {
            this.hasawait = true
            break
        }
    }
    if this.elseCase != null {
        if this.elseCase.block.hasawait {
            this.hasawait = true
        }
    }
}

ChainExpr::checkawait() {
    for it : this.fields {
        if expressionHasAwait(it) {
            this.hasawait = true
            return true
        }
    }
}

BinaryExpr::checkawait(){
	if this.lhs.hasawait {
		this.hasawait = true
	}
	if this.rhs != null && this.rhs.hasawait {
		this.hasawait = true
	}
}

AssignExpr::checkawait(){
	if this.lhs.hasawait {
		this.hasawait = true
	}
    if type(this.lhs) == type(VarExpr) && this.rhs != null {
        propagateVarMemTypeFromRhs(this.lhs, this.rhs)
    }
	if expressionHasAwait(this.rhs) {
		this.hasawait = true
	}	
}
