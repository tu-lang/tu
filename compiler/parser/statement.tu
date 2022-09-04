use ast
use gen

Parser::parseStatement()
{
    node = null
    match this.scanner.curToken {
        ast.IF: {
            this.scanner.scan()
            node = parseIfStmt()
        }
        ast.FOR: {
            this.scanner.scan()
            node = parseForStmt()
        }
        ast.WHILE: {
            this.scanner.scan()
            node = parseWhileStmt()
        }
        ast.RETURN: {
            this.scanner.scan()
            node = parseReturnStmt()
        }
        ast.BREAK: {
            this.scanner.scan()
            node = new gen.BreakStmt(line,column)
        }
        ast.GOTO: {
            this.scanner.scan()
            node = new gen.GotoStmt(scanner.curLex,line,column)
            this.scanner.scan()
        }
        ast.CONTINUE: {
            this.scanner.scan()
            node = new gen.ContinueStmt(line,column)
        }
        ast.MATCH: {
            this.scanner.scan()
            node = parseMatchSmt()
        }
        _ : node = parseExpression()
    }
    return node
}
Parser::parseIfStmt()
{
    node = new gen.IfStmt(line,column)
    
    ifCase = new ast.IfCaseExpr(line,column)
    ifCase.cond = parseExpression()
    
    if this.scanner.curToken == ast.LBRACE {
        ifCase.block = parseBlock(false)
    }else{
        ifCase.block = new Block()
        ifCase.block.stmts[] = parseStatement()
    }
    node.cases[] = ifCase
    
    while this.scanner.curToken == ast.ELSE {
        ice = new ast.IfCaseExpr(line,column)
        this.scanner.scan()
        if this.scanner.curToken == IF{
            this.scanner.scan()
            ice.cond = parseExpression()
            if this.scanner.curToken == ast.LBRACE {
                ice.block = parseBlock(false)
            }else {
                ice.block = new Block()
                ice.block.stmts[] = parseStatement()
            }
            node.cases[] = ice
        
        }else{
            if this.scanner.curToken == ast.LBRACE {
                ice.block = parseBlock(false)
            }else {
                ice.block = new Block()
                ice.block.stmts[] = parseStatement()
            }
            node.elseCase = ice
        }
    }
    return node
}
Parser::parseForStmt()
{
    node = new gen.ForStmt(line,column)
    
    hashlparen = false
    if this.scanner.curToken == ast.LPAREN {
        this.scanner.scan()
        hashlparen = true
    }
    
    this.expect( ast.VAR)

    tx = scanner.transaction()
    // {
        key = null
        value = parseExpression()
        obj = null
        
        if type(value) == type(gen.VarExpr) && (scanner.curToken == ast.COMMA || this.scanner.curToken == ast.COLON) {
            node.range = true
            
            if this.scanner.curToken == ast.COMMA {
                key = value
                this.scanner.scan()
                value = parseExpression()
                check(type(value) == type(gen.VarExpr))
            }
            this.expect( ast.COLON)
            this.scanner.scan()
            obj = parseExpression()
            check(obj != null)

            node.key = null  
            node.value = null 
            node.obj = null
            if key != null   node.key   = key
            if value != null node.value = value
            if obj != null   node.obj   = obj

            if node.key != null 
               && !std.exist(node.key.varname,currentFunc.params_var) 
               && !std.exist(node.key.varname,currentFunc.locals)
                this.currentFunc.locals[node.key.varname] = node.key

            if node.value != null 
               && !std.exist(node.value.varname,currentFunc.params_var)
               && !std.exist(node.value.varname,currentFunc.locals)
                this.currentFunc.locals[node.value.varname] = node.value
            
            if (hashlparen ){
                this.expect(ast.RPAREN)
                this.scanner.scan()
            }
            if this.scanner.curToken == ast.LBRACE {
                node.block = parseBlock(false)
            }else {
                node.block = new ast.Block()
                node.block.stmts[] = this.parseStatement()
            } 
            return node
        }
        
        scanner.rollback(tx)
    // }
    node.init = parseExpression()
    this.expect(ast.SEMICOLON)
    this.scanner.scan()

    node.cond = parseExpression()
    this.expect(ast.SEMICOLON)
    this.scanner.scan()
    
    node.after = parseExpression()
    if (hashlparen ){
        this.expect(ast.RPAREN)
        this.scanner.scan()
    }
    
    if this.scanner.curToken == ast.LBRACE {
        node.block = parseBlock(false)
    }else {
        node.block = new ast.Block()
        node.block.stmts[] = this.parseStatement()
    } 
    return node
}
Parser::parseMatchSmt(){
    ms = new gen.MatchStmt(line,column)
    ms.cond = parseExpression()
    this.expect( ast.LBRACE)
    this.scanner.scan()
    while this.scanner.curToken != ast.RBRACE {
        cs = parseMatchCase(ms.cond)
        if cs.defaultCase {
            ms.defaultCase = cs
            continue
        }
        ms.cases[] = cs
    }
    this.scanner.scan()
    return ms
}
Parser::parseMatchCase(cond)
{
    cs = new ast.MatchCaseExpr(line,column)
    cs.matchCond = cond 

    cs.cond  = cs.bitOrToLogOr(parseExpression())
    cs.block = null
    
    if type(cs.cond) == type(gen.VarExpr) {
        cond = cs.cond
        
        if cond.varname == "_"{
            cs.defaultCase = true
        }
    }
    this.expect( ast.COLON)
    this.scanner.scan()
    if this.scanner.curToken == ast.LBRACE {
        cs.block = parseBlock(false) 
    }else{
        cs.block = new Block()
        cs.block.stmts[] = parseStatement()
    }
    return cs
}
Parser::parseWhileStmt() {
    node = new gen.WhileStmt(line, column)
    
    if this.scanner.curToken == ast.LPAREN {
        this.scanner.scan()
    }
    
    node.cond = parseExpression()
    
    if this.scanner.curToken == ast.RPAREN {
        this.scanner.scan()
    }
    
    node.block = parseBlock(false)
    return node
}
Parser::parseReturnStmt() {
    node = new gen.ReturnStmt(line, column)
    
    node.ret = parseExpression()
    return node
}
