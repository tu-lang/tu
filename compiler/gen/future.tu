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

func annotateVarFromTypeInfo(v, rt, callee){
    if v == null || rt == null
        return null
    // Prefer function-local slot (codegen uses FindLocalVar), not MultiAssign LHS copy.
    target = v
    fcur = compile.currentFunc
    if fcur != null {
        canon = fcur.FindLocalVar(v.varname)
        if canon != null
            target = canon
    }
    if target.structtype || target.isparam
        return null

    if rt.baseType() && rt.base >= ast.I8 && rt.base <= ast.F64 {
        target.structtype = true
        target.structname = ""
        target.structpkg = ""
        target.type = rt.base
        sz = 8
        if rt.base == ast.I8 || rt.base == ast.U8
            sz = 1
        else if rt.base == ast.I16 || rt.base == ast.U16
            sz = 2
        else if rt.base == ast.I32 || rt.base == ast.U32 || rt.base == ast.F32
            sz = 4
        target.size = sz
        target.isunsigned = ast.type_isunsigned(rt.base)
        target.pointer = rt.pointer
        return null
    }
    if rt.memType() {
        st = structFromTypeInfo(rt, callee)
        if st == null && rt.st != null
            st = rt.st
        if st == null
            return null
        full = st.pkg
        if st.parser != null {
            g = st.parser.getpkgname()
            if g != ""
                full = g
        }
        target.structtype = true
        target.structname = st.name
        target.structpkg = full
        target.type = ast.U64
        target.size = 8
        target.isunsigned = true
    }
}

func staticCalleeFromRhs(rhs){
    if rhs == null
        return null
    curf = compile.currentFunc
    if curf == null
        return null
    p = curf.parser
    if p == null
        return null

    if type(rhs) == type(FunCallExpr) {
        fc = rhs
        if fc.package != "" {
            var = ast.GP().getGlobalVar("", fc.package)
            if var == null && curf != null
                var = curf.FindLocalVar(fc.package)
            if var != null
                return null
            parent = p.getStruct("", fc.package)
            if parent != null {
                mfn = parent.getFunc(fc.funcname)
                if mfn != null && std.len(mfn.returnTypes) != 0
                    return mfn
            }
        }
        pkgname = fc.package
        if pkgname != null && pkgname != "" && p.pkg != null && p.pkg.imports[pkgname] != null
            pkgname = p.pkg.imports[pkgname]
        if pkgname == null || pkgname == ""
            pkgname = p.getpkgname()
        if package.packages[pkgname] == null
            return null
        callee = package.packages[pkgname].getFunc(fc.funcname, false)
        if callee != null && std.len(callee.returnTypes) != 0
            return callee
        return null
    }
    if type(rhs) == type(MemberCallExpr) {
        mc = rhs
        parent = null
        if mc.staticCall != null
            parent = mc.staticCall
        else if mc.obj != null {
            if !mc.obj.structtype || mc.obj.structname == ""
                return null
            parent = package.getStruct(mc.obj.structpkg, mc.obj.structname)
        } else if mc.tyassert != null
            parent = mc.tyassert.getStruct()
        if parent == null
            return null
        mfn = parent.getFunc(mc.membername)
        if mfn != null && std.len(mfn.returnTypes) != 0
            return mfn
    }
    return null
}

// Only when every LHS is untyped. Mixed typed+untyped keeps trailing dyn slots.
func propagateMultiAssignStaticRets(stmt){
    if stmt == null || compile.currentFunc == null
        return null
    if stmt.hasawait || std.len(stmt.rs) != 1 || std.len(stmt.ls) < 2
        return null

    i = 0
    while i < std.len(stmt.ls) {
        le = stmt.ls[i]
        if type(le) == type(VarExpr) {
            v = le
            target = v
            canon = compile.currentFunc.FindLocalVar(v.varname)
            if canon != null
                target = canon
            if target.structtype || target.isparam
                return null
        }
        i += 1
    }

    callee = staticCalleeFromRhs(stmt.rs[0])
    if callee == null || std.len(callee.returnTypes) == 0
        return null

    n = std.len(stmt.ls)
    if n > std.len(callee.returnTypes)
        n = std.len(callee.returnTypes)
    i = 0
    while i < n {
        le = stmt.ls[i]
        if type(le) == type(VarExpr)
            annotateVarFromTypeInfo(le, callee.returnTypes[i], callee)
        i += 1
    }
}

func propagateVarMemTypeFromRhs(lhs, rhs){
    if lhs == null || rhs == null
        return null
    if compile.currentFunc == null
        return null
    if expressionHasAwait(rhs)
        return null

    if type(rhs) == type(NewClassExpr) {
        nc = rhs
        if lhs.structtype || lhs.structname != ""
            return null
        pkg = nc.package
        cur = compile.currentFunc.parser
        if pkg == "" && cur != null && cur.pkg != null
            pkg = cur.pkg.full_package
        lhs.structtype = false
        lhs.structname = nc.name
        lhs.structpkg = pkg
        lhs.type = ast.U64
        lhs.size = 8
        lhs.isunsigned = true
        canon = compile.currentFunc.FindLocalVar(lhs.varname)
        if canon != null && canon != lhs && !canon.structtype && canon.structname == "" {
            canon.structtype = false
            canon.structname = nc.name
            canon.structpkg = pkg
            canon.type = ast.U64
            canon.size = 8
            canon.isunsigned = true
        }
        return null
    }

    if type(rhs) == type(FunCallExpr) {
        fc = rhs
        if fc.package != "" {
            recv = ast.GP().getGlobalVar("", fc.package)
            if recv == null
                recv = compile.currentFunc.FindLocalVar(fc.package)
            if recv != null && !recv.structtype && recv.structname != "" {
                cls = package.getClass(recv.structpkg, recv.structname)
                if cls != null {
                    cf = cls.getFunc(fc.funcname)
                    if cf != null && cf.asyncst != null {
                        if lhs.structtype && lhs.structname != ""
                            return null
                        lhs.structtype = true
                        lhs.structname = "Future"
                        lhs.structpkg = "runtime"
                        lhs.type = ast.U64
                        lhs.size = 8
                        lhs.isunsigned = true
                        canon = compile.currentFunc.FindLocalVar(lhs.varname)
                        if canon != null && canon != lhs {
                            if !canon.structtype || canon.structname == "" {
                                canon.structtype = true
                                canon.structname = "Future"
                                canon.structpkg = "runtime"
                                canon.type = ast.U64
                                canon.size = 8
                                canon.isunsigned = true
                            }
                        }
                        return null
                    }
                }
            }
        }
    }

    st = memStructFromRhs(rhs)
    if st != null
        annotateVarWithStruct(lhs, st)
}

MemberCallExpr::checkawait(){
    if this.call != null && this.call.hasawait {
        this.hasawait = true
    }
}

func varIsAwaitable(v){
    if v == null return false
    canon = v
    if compile.currentFunc != null {
        c = compile.currentFunc.FindLocalVar(v.varname)
        if c != null
            canon = c
    }
    if canon.structname == "Future"
        return true
    if canon.structtype && canon.structname != "" {
        st = package.getStruct(canon.structpkg, canon.structname)
        if st != null && st.isasync
            return true
    }
    return false
}

func callExprIsAwaitable(e){
    if e == null return false
    if type(e) == type(FunCallExpr) {
        fc = e
        curf = compile.currentFunc
        p = null
        if curf != null
            p = curf.parser
        if fc.package != null && fc.package != "" && curf != null {
            recv = ast.GP().getGlobalVar("", fc.package)
            if recv == null
                recv = curf.FindLocalVar(fc.package)
            if recv != null && !recv.structtype && recv.structname != "" {
                cls = package.getClass(recv.structpkg, recv.structname)
                if cls != null {
                    cf = cls.getFunc(fc.funcname)
                    if cf != null && cf.asyncst != null
                        return true
                }
            }
            if recv != null && recv.structtype && recv.structname != "" {
                parent = package.getStruct(recv.structpkg, recv.structname)
                if parent != null {
                    asyncfn = parent.resolveAsyncMember(fc.funcname)
                    if asyncfn != null && asyncfn.fntype == ast.AsyncFunc
                        return true
                    mfn = parent.getFunc(fc.funcname)
                    leaf = structFromCalleeReturn(mfn)
                    if leaf != null && (leaf.isasync || leaf.name == "Future")
                        return true
                }
            }
        }
        callee = staticCalleeFromRhs(fc)
        if callee != null {
            if callee.fntype == ast.AsyncFunc
                return true
            leaf = structFromCalleeReturn(callee)
            if leaf != null && (leaf.isasync || leaf.name == "Future")
                return true
        }
        if p != null && (fc.package == null || fc.package == "") {
            pkgname = p.getpkgname()
            if package.packages[pkgname] != null {
                f = package.packages[pkgname].getFunc(fc.funcname, false)
                if f != null && f.fntype == ast.AsyncFunc
                    return true
            }
        }
        return false
    }
    if type(e) == type(MemberCallExpr) {
        mc = e
        parent = null
        if mc.staticCall != null
            parent = mc.staticCall
        else if mc.obj != null && mc.obj.structtype && mc.obj.structname != ""
            parent = package.getStruct(mc.obj.structpkg, mc.obj.structname)
        else if mc.tyassert != null
            parent = mc.tyassert.getStruct()
        if parent == null
            return false
        asyncfn = parent.resolveAsyncMember(mc.membername)
        if asyncfn != null && asyncfn.fntype == ast.AsyncFunc
            return true
        mfn = parent.getFunc(mc.membername)
        leaf = structFromCalleeReturn(mfn)
        if leaf != null && (leaf.isasync || leaf.name == "Future")
            return true
        return false
    }
    return false
}

func exprIsUnaWaitedAwaitable(e){
    if e == null return false
    if expressionHasAwait(e)
        return false
    if type(e) == type(VarExpr)
        return varIsAwaitable(e)
    return callExprIsAwaitable(e)
}

func isPointerOffsetExpr(e){
    if e == null return false
    if expressionHasAwait(e)
        return false
    if type(e) == type(IntExpr) || type(e) == type(FloatExpr)
        return true
    if type(e) == type(VarExpr) {
        v = e
        canon = v
        if compile.currentFunc != null {
            c = compile.currentFunc.FindLocalVar(v.varname)
            if c != null
                canon = c
        }
        if canon == v || canon.type < ast.I8 || canon.type > ast.U64 {
            g = ast.GP().getGlobalVar("", v.varname)
            if g != null
                canon = g
        }
        if canon.structname != ""
            return false
        if canon.type >= ast.I8 && canon.type <= ast.U64
            return true
    }
    return false
}

func rejectUnaWaitedAwaitableOperand(e, other, opt){
    if !exprIsUnaWaitedAwaitable(e)
        return null
    if callExprIsAwaitable(e) {
        e.check(false, "awaitable used in operator without .await")
        return null
    }
    if opt == ast.EQ || opt == ast.NE
        return null
    if (opt == ast.ADD || opt == ast.SUB) && isPointerOffsetExpr(other)
        return null
    e.check(false, "awaitable used in operator without .await")
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
    if expressionHasAwait(this.lhs) {
        this.hasawait = true
    }
    if this.rhs != null && expressionHasAwait(this.rhs) {
        this.hasawait = true
    }
    rejectUnaWaitedAwaitableOperand(this.lhs, this.rhs, this.opt)
    if this.rhs != null
        rejectUnaWaitedAwaitableOperand(this.rhs, this.lhs, this.opt)
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
    if this.opt != ast.ASSIGN && this.rhs != null {
        if exprIsUnaWaitedAwaitable(this.rhs)
            this.rhs.check(false, "awaitable used in operator without .await")
    }
}
