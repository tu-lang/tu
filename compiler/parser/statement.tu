use compiler.ast
use compiler.gen
use compiler.utils
use compiler.compile
use compiler.parser.package
use std

// Value-side classification of an untyped async return (decides whether the
// caller's await result slot is dynamic or static).
//   ARK_STATIC  provably native / mem pointer (type assert, mem local, typed fn ...)
//   ARK_DYN     provably dynamic Value (untyped param, class object, dynamic call ...)
//   ARK_LIT     bare scalar literal: dynamic alone, follows the other side in binary ops
//   ARK_UNKNOWN cannot tell -> keep the static default (or follow recorded deps)
ARK_UNKNOWN = 0
ARK_STATIC  = 1
ARK_DYN     = 2
ARK_LIT     = 3

// Classifies a variable by name: param -> local -> global.
// Untyped locals / globals count as dynamic only in dyn packages.
func arkVar(p, name, deps){
    f = p.currentFunc
    dynmode = p.pkg != null && p.pkg.pkg_mode == PkgModeDyn
    if f != null && f.params_var[name] != null {
        v = f.params_var[name]
        if v.structtype return ARK_STATIC
        return ARK_DYN
    }
    if f != null && std.exist(name, f.params_var) return ARK_DYN
    v = null
    if f != null v = f.FindLocalVar(name)
    if v == null v = p.getGlobalVar("", name)
    if v == null return ARK_UNKNOWN
    if v.structtype return ARK_STATIC
    // class identity recorded by propagateVarMemTypeFromRhs on `x = new C()`
    if v.structname != null && v.structname != "" return ARK_DYN
    // assignment sources seen in this function (asyncNoteLocalAssign)
    if (v.arkAssign & 2) != 0 return ARK_STATIC
    if (v.arkAssign & 1) != 0 return ARK_DYN
    if std.len(v.arkDeps) > 0 {
        std.merge(deps, v.arkDeps)
        return ARK_UNKNOWN
    }
    if dynmode return ARK_DYN
    return ARK_UNKNOWN
}

// Resolves a receiver variable (obj.m() / obj.f / obj[i] / obj.await).
// Returns [kind, var]: non-mem receivers dispatch dynamically (ARK_DYN).
func arkRecv(p, name){
    f = p.currentFunc
    v = null
    if f != null v = f.params_var[name]
    if v == null && f != null v = f.FindLocalVar(name)
    if v == null v = p.getGlobalVar("", name)
    if v == null return ARK_UNKNOWN, null
    if v.structtype return ARK_STATIC, v
    return ARK_DYN, v
}

// Member call on a mem receiver: awaited -> record the async leaf dep;
// sync -> static when the callee declares return types.
func arkStructMember(parent, member, awaited, deps){
    if parent == null return ARK_UNKNOWN
    if awaited {
        af = parent.resolveAsyncMember(member)
        if af != null && af.fntype == ast.AsyncFunc && af.asyncst != null
            deps[] = af.asyncst
        return ARK_UNKNOWN
    }
    mf = parent.getFunc(member)
    if mf != null && std.len(mf.returnTypes) > 0 return ARK_STATIC
    return ARK_UNKNOWN
}

// Struct definition behind a mem-typed variable, or null.
func arkVarStruct(p, v){
    if v == null || !v.structtype || v.structname == null || v.structname == "" return null
    s = null
    if p.pkg != null {
        opkg = p.pkg.getPackage(v.structpkg)
        if opkg != null s = opkg.getStruct(v.structname)
    }
    if s == null s = package.getStruct(v.structpkg, v.structname)
    return s
}

func arkDynOrUnknown(k){
    if k == ARK_DYN return ARK_DYN
    return ARK_UNKNOWN
}

func arkClassify(p, e, deps){
    if e == null return ARK_UNKNOWN
    if e.tyassert != null return ARK_STATIC
    t = type(e)
    if t == type(gen.IntExpr) || t == type(gen.FloatExpr) || t == type(gen.StringExpr) ||
       t == type(gen.BoolExpr) || t == type(gen.NullExpr)
        return ARK_LIT
    if t == type(gen.CharExpr) return ARK_STATIC
    if t == type(gen.ArrayExpr) || t == type(gen.MapExpr) || t == type(gen.ClosureExpr) ||
       t == type(gen.NewClassExpr)
        return ARK_DYN
    if t == type(gen.NewStructExpr) || t == type(gen.StructInitExpr) || t == type(gen.NewExpr) ||
       t == type(gen.AddrExpr)
        return ARK_STATIC
    if t == type(gen.BuiltinFuncExpr) {
        if e.funcname == "sizeof" || e.funcname == "inter_get_bp" || e.funcname == "inter_get_sp"
            return ARK_STATIC
        if e.funcname == "embed" return ARK_UNKNOWN
        return ARK_DYN
    }
    if t == type(gen.VarExpr) {
        if e.structtype return ARK_STATIC
        if !e.hasawait return arkVar(p, e.varname, deps)
        // fut.await: mem / leaf receiver records a dep, otherwise a dynamic await
        rk, rv = arkRecv(p, e.varname)
        if rk != ARK_STATIC return ARK_DYN
        s = arkVarStruct(p, rv)
        if s != null && s.isasync deps[] = s
        return ARK_UNKNOWN
    }
    if t == type(gen.AwaitExpr) {
        // chain / field / index then .await: a dynamic operand yields a dynamic result
        k = arkClassify(p, e.expr, deps)
        if k == ARK_DYN || k == ARK_LIT return ARK_DYN
        return ARK_UNKNOWN
    }
    if t == type(gen.FunCallExpr) {
        awaited = e.hasawait
        if e.package != null && e.package != "" {
            // obj.method(): receiver is a variable
            rk, rv = arkRecv(p, e.package)
            if rk == ARK_DYN return ARK_DYN
            if rk == ARK_STATIC
                return arkStructMember(arkVarStruct(p, rv), e.funcname, awaited, deps)
            // Type::method(): package names the type
            parent = p.getStruct("", e.package)
            if parent != null && !parent.isasync
                return arkStructMember(parent, e.funcname, awaited, deps)
        }
        // Package-level function: map the import alias back to the package name
        pkgname = e.package
        if pkgname == null pkgname = ""
        if pkgname != "" && p.pkg != null && p.pkg.imports[pkgname] != null
            pkgname = p.pkg.imports[pkgname]
        if pkgname == "" pkgname = p.getpkgname()
        callee = null
        if package.packages[pkgname] != null
            callee = package.packages[pkgname].getFunc(e.funcname, false)
        if awaited {
            s = p.getStruct(e.package, e.funcname)
            if s != null && s.isasync {
                deps[] = s
                return ARK_UNKNOWN
            }
            // plain func returning a future: awaited as a dynamic value
            if callee != null && callee.isDynamicDef() && std.len(callee.returnTypes) == 0
                return ARK_DYN
            return ARK_UNKNOWN
        }
        if callee == null return ARK_UNKNOWN
        if std.len(callee.returnTypes) > 0 return ARK_STATIC
        // an un-awaited async call yields a future object (dynamic); func returns dynamic
        if callee.isasync() || callee.isDynamicDef() return ARK_DYN
        return ARK_UNKNOWN
    }
    if t == type(gen.MemberCallExpr) {
        awaited = e.call != null && e.call.hasawait
        if e.staticCall != null
            return arkStructMember(e.staticCall, e.membername, awaited, deps)
        if e.obj != null {
            if !e.obj.structtype {
                rk, rv = arkRecv(p, e.obj.varname)
                if rk != ARK_STATIC return ARK_DYN
                return arkStructMember(arkVarStruct(p, rv), e.membername, awaited, deps)
            }
            return arkStructMember(arkVarStruct(p, e.obj), e.membername, awaited, deps)
        }
        if e.varname != null && e.varname != "" {
            rk, rv = arkRecv(p, e.varname)
            if rk == ARK_DYN return ARK_DYN
            if rk == ARK_STATIC
                return arkStructMember(arkVarStruct(p, rv), e.membername, awaited, deps)
        }
        return ARK_UNKNOWN
    }
    if t == type(gen.ChainExpr) {
        // a chain on a dynamic receiver is dynamically dispatched end to end
        if std.len(e.fields) == 0 return ARK_UNKNOWN
        head = e.fields[0]
        if head.tyassert == null && type(head) == type(gen.VarExpr) && !head.hasawait {
            if head.structtype return ARK_UNKNOWN
            rk, rv = arkRecv(p, head.varname)
            return arkDynOrUnknown(rk)
        }
        hk = arkClassify(p, head, deps)
        if hk == ARK_DYN || hk == ARK_LIT return ARK_DYN
        return ARK_UNKNOWN
    }
    if t == type(gen.MemberExpr) {
        rk, rv = arkRecv(p, e.varname)
        return arkDynOrUnknown(rk)
    }
    if t == type(gen.IndexExpr) {
        if e.varname == null || e.varname == "" || e.is_pkgcall return ARK_UNKNOWN
        rk, rv = arkRecv(p, e.varname)
        return arkDynOrUnknown(rk)
    }
    if t == type(gen.BinaryExpr) {
        // mirrors BinaryExpr codegen: any static side -> native op; else dynamic op
        ld = []
        rd = []
        kl = arkClassify(p, e.lhs, ld)
        kr = arkClassify(p, e.rhs, rd)
        if kl == ARK_STATIC || kr == ARK_STATIC return ARK_STATIC
        if kl == ARK_DYN || kr == ARK_DYN return ARK_DYN
        if kl == ARK_LIT && kr == ARK_LIT return ARK_DYN
        // one side unknown: that side decides; carry its deps
        std.merge(deps, ld)
        std.merge(deps, rd)
        return ARK_UNKNOWN
    }
    return ARK_UNKNOWN
}

// Records the classification of an async return value on the current function:
// dynamic -> async_value_dynamic; unknown -> deps. In dyn packages an unknown
// value with no deps is dynamic too (no static value source exists there).
func arkRecord(p, retexpr){
    // GlobalPhase function nodes are replaced on FunctionPhase re-parse and local
    // type propagation is incomplete then
    if compile.phase != compile.FunctionPhase return
    f = p.currentFunc
    deps = []
    k = arkClassify(p, retexpr, deps)
    if k == ARK_DYN || k == ARK_LIT {
        f.async_value_dynamic = true
        return
    }
    if k != ARK_UNKNOWN return
    if std.len(deps) == 0 {
        if p.pkg != null && p.pkg.pkg_mode == PkgModeDyn
            f.async_value_dynamic = true
        return
    }
    std.merge(f.async_value_deps, deps)
}

// Tracks what an untyped async local is assigned from, so arkVar can tell
// whether reading it yields a dynamic or a static value.
func asyncNoteLocalAssign(lhs, rhs, opt){
    p = compile.currentParser
    if lhs == null || rhs == null || p == null return
    if compile.phase != compile.FunctionPhase return
    f = p.currentFunc
    if f == null || !f.isasync() return
    if lhs.structtype return
    if lhs.package != null && lhs.package != "" return
    if std.exist(lhs.varname, f.params_var) return
    canon = f.FindLocalVar(lhs.varname)
    if canon == null || canon.structtype return
    deps = []
    k = arkClassify(p, rhs, deps)
    // `x = 1` makes x dynamic; a compound `x += 1` keeps x's existing kind
    if k == ARK_DYN || (k == ARK_LIT && opt == ast.ASSIGN)
        canon.arkAssign = canon.arkAssign | 1
    else if k == ARK_STATIC
        canon.arkAssign = canon.arkAssign | 2
    else if k == ARK_UNKNOWN
        std.merge(canon.arkDeps, deps)
}

Parser::parseStatement()
{
    utils.debug("parser.Parser::parseStatement()")
    reader = this.scanner
    node = null
    match reader.curToken {
        ast.IF: {
            reader.scan()
            node = this.parseIfStmt()
        }
        ast.FOR: {
            reader.scan()
            node = this.parseForStmt()
        }
        ast.LOOP: {
            reader.scan()
            node = this.parseWhileStmt(true)
        }
        ast.WHILE: {
            reader.scan()
            node = this.parseWhileStmt(false)
        }
        ast.RETURN: {
            // Record return keyword line before scan(); next token may be on a later line.
            ret_line = reader.line
            reader.scan()
            node = this.parseReturnStmt(ret_line)
        }
        ast.BREAK: {
            reader.scan()
            node = this.parseBreakStmt()
        }
        ast.GOTO: {
            reader.scan()
            node = new gen.GotoStmt(reader.curLex,this.line,this.column)
            reader.scan()
        }
        ast.CONTINUE: {
            reader.scan()
            node = this.parseContinueStmt()
        }
        ast.MATCH: {
            reader.scan()
            node = this.parseMatchSmt()
        }
        ast.TRY: {
            reader.scan()
            node = this.parseTryStmt()
        }
        ast.THROW: {
            reader.scan()
            node = this.parseThrowStmt()
        }
        ast.DEFER: {
            reader.scan()
            node = this.parseDeferStmt()
        }
        ast.UNSAFE: {
            reader.scan()
            node = this.parseUnsafeStmt()
        }
        ast.LBRACE: {
            node = this.parseBlock(false,false)
        }
        _ : {
            stmt_line = this.line
            stmt_col = this.column
            node = this.parseExpression(1)
            if node != null {
                if node.line == null || node.line == 0 {
                    node.line = stmt_line
                    node.column = stmt_col
                }
            }
            if reader.curToken == ast.COMMA {
                node = this.parseMultiAssignStmt(node)
            }
        }
    }
    return node
}
Parser::parseIfStmt()
{
    utils.debug("parser.Parser::parseIfStmt()")
    reader = this.scanner
    node = new gen.IfStmt(this.line,this.column)
    
    ifCase = new gen.IfCaseExpr(this.line,this.column)
    ifCase.cond = this.parseExpression(1)
    this.check(ifCase.cond != null,"condtion is null in if statement")
    
    ifCase.block = this.parseBlock(false,false)
    node.cases[] = ifCase
    
    while reader.curToken == ast.ELSE {
        ice = new gen.IfCaseExpr(this.line,this.column)
        reader.scan()
        if reader.curToken == ast.IF {
            reader.scan()
            ice.cond = this.parseExpression(1)
            ice.block = this.parseBlock(false,false)
            node.cases[] = ice
        
        }else{
            ice.block = this.parseBlock(false,false)
            node.elseCase = ice
        }
    }
    node.checkawait()
    return node
}
Parser::parseForStmt()
{
    utils.debug("parser.Parser::parseForStmt()")
    this.ctx.create()
    reader = this.scanner
    node = new gen.ForStmt(this.line,this.column)
    
    hashlparen = false
    if reader.curToken == ast.LPAREN {
        reader.scan()
        hashlparen = true
    }
    
    this.expect( ast.VAR)

    this.ctx.top().breakto    = node
    this.ctx.top().continueto = node
    // tx = reader.transaction()
    // {
        key = null
        value = this.parseExpression(1)
        node.init = value
        obj = null
        
        if type(value) == type(gen.VarExpr) && (reader.curToken == ast.COMMA || reader.curToken == ast.COLON) {
            node.range = true
            if reader.curToken == ast.COMMA {
                key = value
                reader.scan()
                value = this.parseExpression(1)
                this.check(type(value) == type(gen.VarExpr))
            }
            this.expect( ast.COLON)
            reader.scan()
            obj = this.parseExpression(1)
            this.check(obj != null)

            node.key = null  
            node.value = null 
            node.obj = null
            if key != null   node.key   = key
            if value != null node.value = value
            if obj != null   node.obj   = obj

            // if node.key != null 
            //    && !utils.has(node.key.varname,this.currentFunc.params_var) 
            //    && !utils.has(node.key.varname,this.currentFunc.locals)
            //     this.currentFunc.locals[node.key.varname] = node.key

            // if node.value != null 
            //    && !utils.has(node.value.varname,this.currentFunc.params_var)
            //    && !utils.has(node.value.varname,this.currentFunc.locals)
            //     this.currentFunc.locals[node.value.varname] = node.value
            this.newvar(node.key)
            this.newvar(node.value)

            node.iter = this.currentFunc.getIterVar()
            this.newvar(node.iter)
            
            if (hashlparen ){
                this.expect(ast.RPAREN)
                reader.scan()
            }
            node.block = this.parseBlock(false,true)
            this.ctx.destroy()

            if node.obj.hasawait || gen.exprContainsAwait(node.obj) node.hasawait = true
            if node.block.hasawait node.hasawait = true
            return node
        }
        
        // reader.rollback(tx)
    // }
    // node.init = this.parseExpression(1)
    this.expect(ast.SEMICOLON)
    reader.scan()

    node.cond = this.parseExpression(1)
    this.expect(ast.SEMICOLON)
    reader.scan()
    
    node.after = this.parseExpression(1)
    if (hashlparen ){
        this.expect(ast.RPAREN)
        reader.scan()
    }
    
    node.block = this.parseBlock(false,true)
    this.ctx.destroy()

    if gen.exprContainsAwait(node.init) || gen.exprContainsAwait(node.cond) || gen.exprContainsAwait(node.after) ||
       node.init.hasawait || node.cond.hasawait || node.after.hasawait || node.block.hasawait {
        node.hasawait = true
    }
    return node
}
Parser::parseMatchSmt(){
    utils.debug("parser.Parser::parseMatchSmt()")
    this.ctx.create()
    reader = this.scanner
    ms = new gen.MatchStmt(this.line,this.column)
    this.ctx.top().breakto = ms

    ms.cond = this.parseExpression(1)
    if ms.cond.hasawait || gen.exprContainsAwait(ms.cond)
        ms.hasawait = true
    
    ms.condrecv = this.currentFunc.getMatchcondVar()
    // A cond containing await must not be typed here: exprIsMtype/getType would
    // cache call dispatch that async lowering rewrites later. The lowered rhs
    // assigned to condrecv decides its slot at the first codegen assignment.
    if type(ms.cond) != type(gen.VarExpr) && ms.hasawait {
        ms.condrecv.inferFromInit = true
    }else if type(ms.cond) != type(gen.VarExpr) {
        if gen.exprIsMtype(ms.cond,this.ctx) {
            condrecv = ms.condrecv
            tk = ms.cond.getType(this.ctx)
            condrecv.structtype = true
            condrecv.type = tk
            condrecv.size = typesize[tk]
        }
    }
    this.newvar(ms.condrecv)

    this.expect( ast.LBRACE)
    reader.scan()
    while reader.curToken != ast.RBRACE {
        cs = this.parseMatchCase(ms.cond)
        if cs.hasawait 
            ms.hasawait = true

        if cs.defaultCase {
            ms.defaultCase = cs
            continue
        }
        ms.cases[] = cs
    }
    reader.scan()
    this.ctx.destroy()
    return ms
}
Parser::parseMatchCase(cond)
{
    utils.debug("parser.Parser::parseMatchCase()")
    reader = this.scanner
    cs = new gen.MatchCaseExpr(this.line,this.column)
    cs.matchCond = cond 

    cs.cond  = this.parseExpression(1)
    cs.block = null
    
    if type(cs.cond) == type(gen.VarExpr) {
        cond = cs.cond
        
        if cond.varname == "_"{
            cs.defaultCase = true
        }
    }
    this.expect( ast.COLON)
    reader.scan()
    cs.block = this.parseBlock(false,false)

    if cs.cond.hasawait || gen.exprContainsAwait(cs.cond)
        cs.hasawait = true
    if cs.block.hasawait
        cs.hasawait = true
    return cs
}
Parser::parseWhileStmt(dead) {
    utils.debug("parser.Parser::parseWhileStmt()")
    reader = this.scanner
    node = new gen.WhileStmt(this.line, this.column)
    this.ctx.create()
    this.ctx.top().breakto    = node
    this.ctx.top().continueto = node

    node.dead = dead
    if !dead {
        // Like if: no separate outer-paren stripping, so `while (a || b) && c {`
        // parses as one expression; `while (cond) {` is a paren expr as well.
        node.cond = this.parseExpression(1)
        if node.cond.hasawait || gen.exprContainsAwait(node.cond)
            node.hasawait = true
    } 
    
    node.block = this.parseBlock(false,true)
    if node.block.hasawait
        node.hasawait = true
    this.ctx.destroy()
    return node
}
Parser::parseReturnStmt(ret_line) {
    reader = this.scanner
    utils.debug("parser.Parser::parseReturnStmt()")
    node = new gen.ReturnStmt(this.line, this.column)

    ret = [] 
    if this.currentFunc.isasync() 
        ret[] = new gen.VarExpr("",0,0)

    // Bare return if the first return-expr token is on a later line than
    // the return keyword. Same-line `return expr` / `return a,\n b` keep working
    // (only the first expression's line is gated).
    if reader.line > ret_line {
        fc = this.currentFunc
        this.check(fc != null)
        if fc.mcount < std.len(ret)
            fc.mcount = std.len(ret)
        node.ret = ret
        return node
    }

    loop {
        retexpr = this.parseExpression(1)
        if retexpr != null{
            ret[] = retexpr
            if retexpr.hasawait || gen.expressionHasAwait(retexpr) || gen.exprContainsAwait(retexpr) {
                node.hasawait = true
            }
            // Untyped async: classify the value side (first returned expr only;
            // reliable once FunctionPhase local type propagation is done)
            if this.currentFunc.isasync() && std.len(ret) == 2
                arkRecord(this, retexpr)
        }

        if reader.curToken != ast.COMMA
            break
        else 
            reader.scan()
    }
    fc = this.currentFunc
    this.check(fc != null)
    count = std.len(ret)
    // return callee(): sole call may forward N returns while ret.size()==1.
    // Static: mcount must equal declared (pad/trunc at codegen).
    // Dynamic: lift from callee mcount. Chain field end must not raise.
    // Async `return inner.poll(ctx)` is size==1 sole call (not PollReady,x).
    start = 0
    if fc.isasync() && std.len(ret) > 0
        start = 1
    sole_forward = false
    if std.len(ret) - start == 1
        sole_forward = true
    if fc.isasync() && std.len(ret) == 1
        sole_forward = true
    if sole_forward {
        sole = ret[0]
        if fc.isasync() && std.len(ret) > 1
            sole = ret[start]
        is_call = false
        if sole != null {
            if type(sole) == type(gen.FunCallExpr) || type(sole) == type(gen.MemberCallExpr)
                is_call = true
            else if type(sole) == type(gen.ChainExpr) {
                ch = sole
                if std.len(ch.fields) > 0 {
                    last = std.tail(ch.fields)
                    if type(last) == type(gen.FunCallExpr) || type(last) == type(gen.MemberCallExpr)
                        is_call = true
                }
            }
        }
        if is_call {
            declared = std.len(fc.returnTypes)
            // Declared > 0: exact declared arity (do not raise to callee).
            if declared > 0 {
                count = declared
            } else if compile.phase == compile.FunctionPhase && sole != null {
                fce = null
                mce = null
                if type(sole) == type(gen.FunCallExpr)
                    fce = sole
                else if type(sole) == type(gen.MemberCallExpr)
                    mce = sole
                else if type(sole) == type(gen.ChainExpr) {
                    ch = sole
                    if std.len(ch.fields) > 0 {
                        last = std.tail(ch.fields)
                        if type(last) == type(gen.FunCallExpr)
                            fce = last
                        else if type(last) == type(gen.MemberCallExpr)
                            mce = last
                    }
                }
                callee = null
                method = ""
                if fce != null && fce.funcname != "" {
                    if fce.is_pkgcall && fce.package != ""
                        // gen.getGLobalFunc (Package::getGLobalFunc); not parser.package
                        callee = gen.getGLobalFunc(fce.package, fce.funcname)
                    else
                        callee = this.getFunc(fce.funcname, false)
                    if callee == null
                        method = fce.funcname
                } else if mce != null && mce.membername != "" {
                    method = mce.membername
                }
                // Class/struct methods: scan tables; prefer higher mcount (poll).
                if callee == null && method != "" {
                    best = null
                    for k, f : this.funcs {
                        if f != null && f.name == method {
                            if best == null || f.mcount > best.mcount
                                best = f
                        }
                    }
                    if this.pkg != null {
                        for k, cls : this.pkg.classes {
                            for f : cls.funcs {
                                if f != null && f.name == method {
                                    if best == null || f.mcount > best.mcount
                                        best = f
                                }
                            }
                        }
                        for k, st : this.pkg.structs {
                            if utils.has(method, st.funcs) {
                                f = st.funcs[method]
                                if f != null {
                                    if best == null || f.mcount > best.mcount
                                        best = f
                                }
                            }
                        }
                    }
                    callee = best
                }
                if callee != null && callee.mcount > count
                    count = callee.mcount
            }
        }
    }
    if fc.mcount < count
        fc.mcount = count

    node.ret = ret
    return node
}

Parser::parseMultiAssignStmt(firstv){
    utils.debug("parser.Parser::parseMultiAssignStmt()")
    reader = this.scanner

    this.expect(ast.COMMA)
    reader.scan()

    this.lassigner(firstv)
    this.newvar(firstv)

    this.ismultiassign = true
    stmt = new gen.MultiAssignStmt(this.line,this.column)
    stmt.ls[] = firstv
    stmt.opt = ast.ASSIGN
    loop {
        p = this.parseExpression()
        this.lassigner(p)
        if type(p) == type(gen.StructMemberExpr) && this.currentFunc {
            p.assign = true
        }
        this.newvar(p)
        stmt.ls[] = p

        tk = reader.curToken
        if tk == ast.COMMA {
            reader.scan()
        }else if this.isassign() {
            stmt.opt = reader.curToken
            reader.scan()
            break
        }else{
            this.check(false,"parse multi var error")
        }
    }
    loop {
        p = this.parseExpression()
        if p.hasawait || gen.expressionHasAwait(p) || gen.exprContainsAwait(p)
            stmt.hasawait = true
        stmt.rs[] = p
        if reader.curToken != ast.COMMA 
            break
        reader.scan()
    }

    // One-to-one multi-assign: propagate mem/leaf onto untyped locals
    if !stmt.hasawait && std.len(stmt.ls) == std.len(stmt.rs) {
        i = 0
        while i < std.len(stmt.ls) {
            if type(stmt.ls[i]) == type(gen.VarExpr)
                gen.propagateVarMemTypeFromRhs(stmt.ls[i], stmt.rs[i])
            i += 1
        }
    }
    if !stmt.hasawait && std.len(stmt.rs) == 1 && std.len(stmt.ls) > 1 {
        gen.propagateMultiAssignStaticRets(stmt)
    }

    this.ismultiassign = false
    return stmt
}

Parser::parseBreakStmt(){
    bs = new gen.BreakStmt(this.line,this.column)

    if this.currentFunc.isasync() == null {
        return bs
    }

    stmt = null
    for(i = std.len(this.ctx.ctxs) - 1 ; i >= 0 ; i -= 1){
        p = this.ctx.ctxs[i]
        if p.breakto != null {
            stmt = p.breakto
            break
        }
    }
    if stmt == null {
        this.check(false,"break not in while for match")
    }
    if type(stmt) != type(gen.ForStmt) && type(stmt) != type(gen.WhileStmt) && type(stmt) != type(gen.MatchStmt) {
        this.check(false,"break to invalid stmt")
    }
    bs.breakto = stmt
    return bs
}

Parser::parseContinueStmt(){
    cs = new gen.ContinueStmt(this.line,this.column)

    if !this.currentFunc.isasync() {
        return cs
    }

    stmt = null
    for(i = std.len(this.ctx.ctxs) - 1 ; i >= 0 ; i -= 1){
        p = this.ctx.ctxs[i]
        if p.continueto != null {
            stmt = p.continueto
            break
        }
    }
    if stmt == null {
        this.check(false,"continue not in while for match")
    }
    if type(stmt) != type(gen.ForStmt) && type(stmt) != type(gen.WhileStmt) {
        this.check(false,"break to invalid stmt")
    }
    cs.continueto = stmt
    return cs
}
Parser::parseTryStmt(){
	utils.debug("parser.Parser::parseTryStmt()")
	if this.currentFunc != null && this.currentFunc.isasync() {
		this.check(false, "try/catch/finally not supported inside async (see RFC-106)")
	}
	reader = this.scanner
	node = new gen.TryStmt(this.line, this.column)
	jbid = ast.incr_labelid()
	jb = new gen.VarExpr(".jmpbuf." + jbid, this.line, this.column)
	jb.structtype = true
	jb.type = ast.I64
	jb.size = 8
	jb.stack = true
	jb.stacksize = 8
	this.newvar(jb)
	node.jmpbufVar = jb
	node.tryBlock = this.parseBlock(false, false)
	this.check(node.tryBlock != null, "try requires a block")
	while reader.curToken == ast.CATCH {
		reader.scan()
		cc = new gen.CatchClause()
		cc.line = this.line
		cc.column = this.column
		this.check(reader.curToken == ast.LPAREN, "catch expects (")
		reader.scan()
		this.check(reader.curToken == ast.VAR, "catch expects type or name")
		first = reader.curLex
		reader.scan()
		if reader.curToken == ast.VAR {
			cc.typeName = first
			cc.varName = reader.curLex
			reader.scan()
		} else {
			cc.typeName = ""
			cc.varName = first
		}
		this.check(reader.curToken == ast.RPAREN, "catch expects )")
		reader.scan()
		if cc.varName != "" {
			ve = new gen.VarExpr(cc.varName, cc.line, cc.column)
			this.newvar(ve)
			cc.varExpr = ve
		}
		cc.block = this.parseBlock(false, false)
		this.check(cc.block != null, "catch requires a block")
		node.catches[] = cc
	}
	if reader.curToken == ast.FINALLY {
		reader.scan()
		node.finallyBlock = this.parseBlock(false, false)
		this.check(node.finallyBlock != null, "finally requires a block")
	}
	this.check(std.len(node.catches) > 0 || node.finallyBlock != null, "try requires catch or finally")
	return node
}

Parser::parseThrowStmt(){
	utils.debug("parser.Parser::parseThrowStmt()")
	if this.currentFunc != null && this.currentFunc.isasync() {
		this.check(false, "throw not supported inside async (see RFC-106)")
	}
	node = new gen.ThrowStmt(this.line, this.column)
	node.expr = this.parseExpression(1)
	this.check(node.expr != null, "throw requires an expression")
	return node
}

Parser::parseDeferStmt(){
	utils.debug("parser.Parser::parseDeferStmt()")
	if this.currentFunc != null && this.currentFunc.isasync() {
		this.check(false, "defer not supported inside async (see RFC-106)")
	}
	reader = this.scanner
	node = new gen.DeferStmt(this.line, this.column)
	if this.currentFunc != null {
		this.currentFunc.has_defer = true
	}
	if reader.curToken == ast.LBRACE {
		node.block = this.parseBlock(false, false)
	} else {
		b = new gen.BlockStmt()
		s = this.parseStatement()
		this.check(s != null, "defer requires a statement")
		b.stmts[] = s
		node.block = b
	}
	this.check(node.block != null, "defer requires a block")
	return node
}

// RFC110: unsafe must be followed by an explicit block.
Parser::parseUnsafeStmt() {
	reader = this.scanner
	this.check(reader.curToken == ast.LBRACE, "pkgmode: unsafe must be followed by { block }")
	node = new gen.UnsafeStmt(this.line, this.column)
	this.unsafe_stmt_depth += 1
	node.block = this.parseBlock(false, false)
	this.unsafe_stmt_depth -= 1
	return node
}
