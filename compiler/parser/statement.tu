use compiler.ast
use compiler.gen
use compiler.utils
use compiler.compile
use compiler.parser.package
use std

Parser::parseStatement()
{
    utils.debug("parser.Parser::parseStatement()")
    reader<scanner.ScannerStatic> = this.scanner
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
            ret_line<i32> = reader.line
            reader.scan()
            node = this.parseReturnStmt(ret_line)
        }
        ast.BREAK: {
            reader.scan()
            node = this.parseBreakStmt()
        }
        ast.GOTO: {
            reader.scan()
            node = new gen.GotoStmt(reader.curLex.dyn(),this.line,this.column)
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
    reader<scanner.ScannerStatic> = this.scanner
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
    reader<scanner.ScannerStatic> = this.scanner
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
            //    && !std.exist(node.key.varname,this.currentFunc.params_var) 
            //    && !std.exist(node.key.varname,this.currentFunc.locals)
            //     this.currentFunc.locals[node.key.varname] = node.key

            // if node.value != null 
            //    && !std.exist(node.value.varname,this.currentFunc.params_var)
            //    && !std.exist(node.value.varname,this.currentFunc.locals)
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

            if node.obj.hasawait   node.hasawait = true
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

    if node.init.hasawait || node.cond.hasawait || node.after.hasawait || node.block.hasawait {
        node.hasawait = true
    }
    return node
}
Parser::parseMatchSmt(){
    utils.debug("parser.Parser::parseMatchSmt()")
    this.ctx.create()
    reader<scanner.ScannerStatic> = this.scanner
    ms = new gen.MatchStmt(this.line,this.column)
    this.ctx.top().breakto = ms

    ms.cond = this.parseExpression(1)
    if ms.cond.hasawait
        ms.hasawait = true
    
    ms.condrecv = this.currentFunc.getMatchcondVar()
    if type(ms.cond) != type(gen.VarExpr) {
        if gen.exprIsMtype(ms.cond,this.ctx) {
            condrecv = ms.condrecv
            tk = ms.cond.getType(this.ctx)
            condrecv.structtype = true
            condrecv.type = tk
            condrecv.size = typesize[int(tk)]
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
    reader<scanner.ScannerStatic> = this.scanner
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

    if cs.cond.hasawait
        cs.hasawait = true
    if cs.block.hasawait
        cs.hasawait = true
    return cs
}
Parser::parseWhileStmt(dead) {
    utils.debug("parser.Parser::parseWhileStmt()")
    reader<scanner.ScannerStatic> = this.scanner
    node = new gen.WhileStmt(this.line, this.column)
    this.ctx.create()
    this.ctx.top().breakto    = node
    this.ctx.top().continueto = node

    node.dead = dead
    if !dead {
        if reader.curToken == ast.LPAREN {
            reader.scan()
        }
        
        node.cond = this.parseExpression(1)
        if node.cond.hasawait
            node.hasawait = true
        
        if reader.curToken == ast.RPAREN {
            reader.scan()
        }
    } 
    
    node.block = this.parseBlock(false,true)
    if node.block.hasawait
        node.hasawait = true
    this.ctx.destroy()
    return node
}
Parser::parseReturnStmt(ret_line<i32>) {
    reader<scanner.ScannerStatic> = this.scanner
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
            if retexpr.hasawait || gen.expressionHasAwait(retexpr) {
                node.hasawait = true
            }
            // Untyped async value returns: bare int/array → dynamic await slot
            if this.currentFunc.isasync() && retexpr.tyassert == null {
                if type(retexpr) == type(gen.IntExpr) ||
                   type(retexpr) == type(gen.FloatExpr) ||
                   type(retexpr) == type(gen.StringExpr) ||
                   type(retexpr) == type(gen.BoolExpr) ||
                   type(retexpr) == type(gen.ArrayExpr) ||
                   type(retexpr) == type(gen.MapExpr) ||
                   type(retexpr) == type(gen.NullExpr) {
                    this.currentFunc.async_value_dynamic = true
                }
            }
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
                            if std.exist(method, st.funcs) {
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
    reader<scanner.ScannerStatic> = this.scanner

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

        tk<i32> = reader.curToken
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
        if p.hasawait || gen.expressionHasAwait(p)
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
	reader<scanner.ScannerStatic> = this.scanner
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
		first = reader.curLex.dyn()
		reader.scan()
		if reader.curToken == ast.VAR {
			cc.typeName = first
			cc.varName = reader.curLex.dyn()
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
	reader<scanner.ScannerStatic> = this.scanner
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
