use compiler.ast
use compiler.gen
use compiler.utils

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
            reader.scan()
            node = this.parseReturnStmt()
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
        ast.LBRACE: {
            node = this.parseBlock(false,false)
        }
        _ : {
            node = this.parseExpression(1)
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
Parser::parseReturnStmt() {
    reader<scanner.ScannerStatic> = this.scanner
    utils.debug("parser.Parser::parseReturnStmt()")
    node = new gen.ReturnStmt(this.line, this.column)

    ret = [] 
    if this.currentFunc.isasync() 
        ret[] = new gen.VarExpr("",0,0)
    loop {
        retexpr = this.parseExpression(1)
        if retexpr != null{
            ret[] = retexpr
            if retexpr.hasawait {
                node.hasawait = true
            }
        }

        if reader.curToken != ast.COMMA
            break
        else 
            reader.scan()
    }
    fc = this.currentFunc
    this.check(fc != null)

    if fc.mcount < std.len(ret)
        fc.mcount = std.len(ret)

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
        if p.hasawait
            stmt.hasawait = true
        stmt.rs[] = p
        if reader.curToken != ast.COMMA 
            break
        reader.scan()
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