use ast

Parser::parseStatement()
{
    node = null
    match scanner.curToken {
        ast.IF: {
            scanner.scan()
            node = parseIfStmt()
        }
        ast.FOR: {
            scanner.scan()
            node = parseForStmt()
        }
        ast.WHILE: {
            scanner.scan()
            node = parseWhileStmt()
        }
        ast.RETURN: {
            scanner.scan()
            node = parseReturnStmt()
        }
        ast.BREAK: {
            scanner.scan()
            node = new BreakStmt(line,column)
        }
        ast.GOTO: {
            scanner.scan()
            node = new GotoStmt(scanner.curLex,line,column)
            scanner.scan()
        }
        ast.CONTINUE: {
            scanner.scan()
            node = new ContinueStmt(line,column)
        }
        ast.MATCH: {
            scanner.scan()
            node = parseMatchSmt()
        }
        _ : node = parseExpressionStmt()
    }
    return node
}
Parser::parseIfStmt()
{
    node = new ast.IfStmt(line,column)
    
    ifCase = new ast.IfCaseExpr(line,column)
    ifCase.cond = parseExpression()
    
    if scanner.curToken == ast.LBRACE {
        ifCase.block = parseBlock()
    }else{
        ifCase.block = new Block()
        ifCase.block.stmts[] = parseStatement()
    }
    node.cases[] = ifCase
    
    while scanner.curToken == ast.ELSE {
        ice = new ast.IfCaseExpr(line,column)
        scanner.scan()
        if scanner.curToken == IF{
            scanner.scan()
            ice.cond = parseExpression()
            if scanner.curToken == ast.LBRACE {
                ice.block = parseBlock()
            }else {
                ice.block = new Block()
                ice.block.stmts[] = parseStatement();
            }
            node.cases[] = ice
        
        }else{
            if scanner.curToken == ast.LBRACE {
                ice.block = parseBlock()
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
    node = new ForStmt(line,column)
    
    scanner.scan()
    
    check(scanner.curToken == ast.VAR)

    tx = scanner.transaction()
    {
        key = null
        value = parseExpression()
        obj = null
        
        if type(value) == type(ast.VarExpr) && (scanner.curToken == ast.COMMA || scanner.curToken == ast.COLON) {
            node.range = true
            
            if scanner.curToken == ast.COMMA {
                key = value
                scanner.scan()
                value = parseExpression()
                check(type(value) == type(ast.VarExpr) 
            }
            check(scanner.curToken == ast.COLON)
            scanner.scan()
            obj = parseExpression()
            check(obj != null)

            node.key = null  
            node.value = null 
            node.obj = null
            if key != null   node.key   = key
            if value != null node.value = value
            if obj != null   node.obj   = obj

            if node.key != null 
               && !std.exist(currentFunc.params_var,node.key.varname) 
               && !std.exist(currentFunc.locals,node.key.varname)
                currentFunc.locals[node.key.varname] = node.key

            if node.value != null 
               && !std.exist(currentFunc.params_var,node.value.varname)
               && !std.exist(currentFunc.locals,node.value.varname)
                currentFunc.locals[node.value.varname] = node.value
            
            fmt.assert(scanner.curToken == ast.RPAREN)
            scanner.scan()
            
            node.block = parseBlock()
            return node
        }
        
        scanner.rollback(tx)
    }
    node.init = parseExpression()
    check(scanner.curToken == ast.SEMI ast.COLON)
    scanner.scan()

    node.cond = parseExpression()
    assert(scanner.curToken == ast.SEMI ast.COLON)
    scanner.scan()
    
    node.after = parseExpression()
    assert(scanner.curToken == ast.RPAREN)
    scanner.scan()
    
    node.block = parseBlock()
    return node
}
Parser::parseMatchSmt(){
    ms = new MatchStmt(line,column)
    ms.cond = parseExpression()
    check(scanner.curToken == ast.LBRACE)
    scanner.scan()
    while scanner.curToken != ast.RBRACE {
        cs = parseMatchCase()
        cs.matchCond = ms.cond
        if cs.defaultCase {
            ms.defaultCase = cs
            continue
        }
        ms.cases[] = cs
    }
    scanner.scan()
    return ms
}
Parser::parseMatchCase()
{
    cs = new ast.MatchCaseExpr(line,column)
    
    cs.cond  = parseExpression()
    cs.block = null
    
    if type(cs.cond == type(ast.VarExpr) {
        cond = cs.cond
        
        if cond.varname == "_"{
            cs.defaultCase = true
        }
    }
    check(scanner.curToken == ast.COLON)
    scanner.scan()
    if scanner.curToken == ast.LBRACE {
        cs.block = parseBlock(); 
    }else{
        cs.block = new Block()
        cs.block.stmts[] = parseStatement()
    }
    return cs
}
Parser::parseWhileStmt() {
    node = new WhileStmt(line, column)
    
    if scanner.curToken == ast.LPAREN {
        scanner.scan()
    }
    
    node.cond = parseExpression()
    
    if scanner.curToken == ast.RPAREN {
        scanner.scan()
    }
    
    node.block = parseBlock()
    return node
}
Parser::parseReturnStmt() {
    node = new ReturnStmt(line, column)
    
    node.ret = parseExpression()
    return node
}
Parser::parseExpressionStmt()
{
    p = parseExpression()
    if p != null
        return new ExpressionStmt(p,line,column)
    return null
}