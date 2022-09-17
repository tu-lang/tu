use ast
use gen
use utils

Parser::parseStatement()
{
    utils.debug("parser.Parser::parseStatement()")
    node = null
    match this.scanner.curToken {
        ast.IF: {
            this.scanner.scan()
            node = this.parseIfStmt()
        }
        ast.FOR: {
            this.scanner.scan()
            node = this.parseForStmt()
        }
        ast.WHILE: {
            this.scanner.scan()
            node = this.parseWhileStmt()
        }
        ast.RETURN: {
            this.scanner.scan()
            node = this.parseReturnStmt()
        }
        ast.BREAK: {
            this.scanner.scan()
            node = new gen.BreakStmt(this.line,this.column)
        }
        ast.GOTO: {
            this.scanner.scan()
            node = new gen.GotoStmt(this.scanner.curLex,this.line,this.column)
            this.scanner.scan()
        }
        ast.CONTINUE: {
            this.scanner.scan()
            node = new gen.ContinueStmt(this.line,this.column)
        }
        ast.MATCH: {
            this.scanner.scan()
            node = this.parseMatchSmt()
        }
        _ : node = this.parseExpression()
    }
    return node
}
Parser::parseIfStmt()
{
    utils.debug("parser.Parser::parseIfStmt()")
    node = new gen.IfStmt(this.line,this.column)
    
    ifCase = new gen.IfCaseExpr(this.line,this.column)
    ifCase.cond = this.parseExpression()
    
    if this.scanner.curToken == ast.LBRACE {
        ifCase.block = this.parseBlock(false)
    }else{
        ifCase.block = new ast.Block()
        ifCase.block.stmts[] = this.parseStatement()
    }
    node.cases[] = ifCase
    
    while this.scanner.curToken == ast.ELSE {
        ice = new gen.IfCaseExpr(this.line,this.column)
        this.scanner.scan()
        if this.scanner.curToken == ast.IF {
            this.scanner.scan()
            ice.cond = this.parseExpression()
            if this.scanner.curToken == ast.LBRACE {
                ice.block =this. parseBlock(false)
            }else {
                ice.block = new ast.Block()
                ice.block.stmts[] = this.parseStatement()
            }
            node.cases[] = ice
        
        }else{
            if this.scanner.curToken == ast.LBRACE {
                ice.block = this.parseBlock(false)
            }else {
                ice.block = new ast.Block()
                ice.block.stmts[] = this.parseStatement()
            }
            node.elseCase = ice
        }
    }
    return node
}
Parser::parseForStmt()
{
    utils.debug("parser.Parser::parseForStmt()")
    node = new gen.ForStmt(this.line,this.column)
    
    hashlparen = false
    if this.scanner.curToken == ast.LPAREN {
        this.scanner.scan()
        hashlparen = true
    }
    
    this.expect( ast.VAR)

    tx = this.scanner.transaction()
    // {
        key = null
        value = this.parseExpression()
        obj = null
        
        if type(value) == type(gen.VarExpr) && (this.scanner.curToken == ast.COMMA || this.scanner.curToken == ast.COLON) {
            node.range = true
            
            if this.scanner.curToken == ast.COMMA {
                key = value
                this.scanner.scan()
                value = this.parseExpression()
                this.check(type(value) == type(gen.VarExpr))
            }
            this.expect( ast.COLON)
            this.scanner.scan()
            obj = this.parseExpression()
            this.check(obj != null)

            node.key = null  
            node.value = null 
            node.obj = null
            if key != null   node.key   = key
            if value != null node.value = value
            if obj != null   node.obj   = obj

            if node.key != null 
               && !std.exist(node.key.varname,this.currentFunc.params_var) 
               && !std.exist(node.key.varname,this.currentFunc.locals)
                this.currentFunc.locals[node.key.varname] = node.key

            if node.value != null 
               && !std.exist(node.value.varname,this.currentFunc.params_var)
               && !std.exist(node.value.varname,this.currentFunc.locals)
                this.currentFunc.locals[node.value.varname] = node.value
            
            if (hashlparen ){
                this.expect(ast.RPAREN)
                this.scanner.scan()
            }
            if this.scanner.curToken == ast.LBRACE {
                node.block = this.parseBlock(false)
            }else {
                node.block = new ast.Block()
                node.block.stmts[] = this.parseStatement()
            } 
            return node
        }
        
        this.scanner.rollback(tx)
    // }
    node.init = this.parseExpression()
    this.expect(ast.SEMICOLON)
    this.scanner.scan()

    node.cond = this.parseExpression()
    this.expect(ast.SEMICOLON)
    this.scanner.scan()
    
    node.after = this.parseExpression()
    if (hashlparen ){
        this.expect(ast.RPAREN)
        this.scanner.scan()
    }
    
    if this.scanner.curToken == ast.LBRACE {
        node.block = this.parseBlock(false)
    }else {
        node.block = new ast.Block()
        node.block.stmts[] = this.parseStatement()
    } 
    return node
}
Parser::parseMatchSmt(){
    utils.debug("parser.Parser::parseMatchSmt()")
    ms = new gen.MatchStmt(this.line,this.column)
    ms.cond = this.parseExpression()
    this.expect( ast.LBRACE)
    this.scanner.scan()
    while this.scanner.curToken != ast.RBRACE {
        cs = this.parseMatchCase(ms.cond)
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
    utils.debug("parser.Parser::parseMatchCase()")
    cs = new gen.MatchCaseExpr(this.line,this.column)
    cs.matchCond = cond 

    cs.cond  = cs.bitOrToLogOr(this.parseExpression())
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
        cs.block = this.parseBlock(false) 
    }else{
        cs.block = new ast.Block()
        cs.block.stmts[] = this.parseStatement()
    }
    return cs
}
Parser::parseWhileStmt() {
    utils.debug("parser.Parser::parseWhileStmt()")
    node = new gen.WhileStmt(this.line, this.column)
    
    if this.scanner.curToken == ast.LPAREN {
        this.scanner.scan()
    }
    
    node.cond = this.parseExpression()
    
    if this.scanner.curToken == ast.RPAREN {
        this.scanner.scan()
    }
    
    node.block = this.parseBlock(false)
    return node
}
Parser::parseReturnStmt() {
    utils.debug("parser.Parser::parseReturnStmt()")
    node = new gen.ReturnStmt(this.line, this.column)
    
    node.ret = this.parseExpression()
    return node
}
