
Parser::parseChainExpr(first){
    
    chainExpr = new ast.ChainExpr(line,column)
    ret  = chainExpr
    chainExpr.first = first
    if type(first) == type(ast.DelRefExpr) {
        dr = first
        check(type(dr.expr) == type(ast.StructMemberExpr) 
        
        chainExpr.first = dr.expr
        dr.expr = chainExpr
        ret = dr
    }else if type(first) == type(ast.AddrExpr) {
        ae = first
        
        var = currentFunc.getVar(ae.package)
        check(var != null && var.structtype)
        
        sm = new StructMemberExpr(ae.package,ae.line,ae.column)
        sm.member = ae.varname
        sm.var    = var
        
        chainExpr.first = sm
        ae.expr = chainExpr
        ret = ae
    }
    
    
    while std.exist(scanner.curToken,[DOT,LPAREN,LBRACKET]) {
        match scanner.curToken {
            ast.DOT : {
                scanner.scan()
                me = new MemberExpr(line,column)
                me.membername = scanner.curLex
                chainExpr.fields[] = me
                
                scanner.scan()
            }
            ast.LPAREN :   chainExpr.fields[] = parseFuncallExpr("")
            ast.LBRACKET : chainExpr.fields[] = parseIndexExpr("")
        }
    }
    check(std.len(chainExpr.fields),"parse chain expression,need at least 2 field")
    chainExpr.last =  chainExpr.std.back(fields)
    chainExpr.fields.pop_back()

    return ret
}

Parser::parseExpression(oldPrecedence)
{
    
    p = parseUnaryExpr()
    
    if anyone(scanner.curToken,DOT,LPAREN,LBRACKET){
        p = parseChainExpr(p)
    }
    
    if std.exist(scanner.curToken,
                [ASSIGN, ADD_ASSIGN, SUB_ASSIGN,MUL_ASSIGN, DIV_ASSIGN, 
                MOD_ASSIGN,BITAND_ASSIGN,BITOR_ASSIGN,SHL_ASSIGN,SHR_ASSIGN
                ]) 
    {
        check(p != null)
        if (type(p) != type(VarExpr) &&
            type(p) != type(ChainExpr) &&
            type(p) != type(IndexExpr) &&
            type(p) != type(MemberExpr) &&
            type(p) != type(DelRefExpr) &&
            type(p) != type(ast.StructMemberExpr)  {
            check(false,"ParseError: can not assign to " + string(type(p).name()))
        }
        
        if (type(p) == type(ast.StructMemberExpr) && currentFunc){
            sm = p
            sm.assign = true
        }
        if (type(p) == type(VarExpr) && currentFunc){
            var = p
            
            if std.len(!currentFunc.params_var,var.varname && !currentFunc.locals.count(var.varname)){
                currentFunc.locals[var.varname] = var
            }
        }

        
        assignExpr = new AssignExpr(line, column)
        assignExpr.opt = scanner.curToken
        assignExpr.lhs = p
        scanner.scan()
        assignExpr.rhs = parseExpression()
        return assignExpr
    }

    
    while std.exist(scanner.curToken,[SHL,SHR,BITOR, BITAND, BITNOT, LOGOR,
                  LOGAND, LOGNOT, EQ, NE, GT, GE, LT,
                  LE, ADD, SUB, MOD, ast.MUL, DIV])
    {
        currentPrecedence = scanner.precedence(scanner.curToken)
        if (oldPrecedence > currentPrecedence)
            return p
        
        tmp = new BinaryExpr(line, column)
        tmp.lhs = p
        tmp.opt = scanner.curToken
        scanner.scan()
        tmp.rhs = parseExpression(currentPrecedence + 1)
        p = tmp
    }
    return p
}

Parser::parseUnaryExpr()
{
    if std.exist(scanner.curToken,[SUB,LOGNOT,BITNOT]) {
        val = new BinaryExpr(line,column)
        val.opt = scanner.curToken
        
        scanner.scan()
        val.lhs = parseUnaryExpr()
        return val
    }else if std.exist(scanner.curToken,[FLOAT,INT,CHAR,STRING,VAR,FUNC,LPAREN,LBRACKET,
                    ast.LBRACE,RBRACE,BOOL,EMPTY,NEW,DOT,DELREF,BITAND,BUILTIN]){
        return parsePrimaryExpr()
    }
    utils.debug("parseUnaryExpr: not found token:%d-%s file:%s line:%d",scanner.curToken,scanner.curLex,filepath,line)
    return null
}

Parser::parsePrimaryExpr()
{
    tk   = scanner.curToken
    Token prev = scanner.prevToken
    
    if tk == BUILTIN {
        BuiltinFuncExpr* builtinfunc = new BuiltinFuncExpr(scanner.curLex,scanner.line,scanner.column)
        check(scanner.scan() == ast.LPAREN)
        scanner.scan()
        
        if scanner.curToken == ast.MUL{
            builtinfunc.expr = parsePrimaryExpr()
        }else{
            builtinfunc.expr = parseExpression()
        }

        check(scanner.curToken == ast.RPAREN)
        scanner.scan()
        return builtinfunc
    }
    
    if tk == BITAND {
        addr = new AddrExpr(scanner.line,scanner.column)
        tk = scanner.scan()
        if tk == ast.VAR{
            addr.varname = scanner.curLex
        }
        tk = scanner.scan()
        if tk == ast.DOT{
            addr.package = addr.varname
            scanner.scan()
            assert(scanner.curToken == ast.VAR)
            addr.varname = scanner.curLex
            scanner.scan()
        }
        return addr
    }
    if tk == DELREF || tk == ast.MUL{
        utils.debug("find token delref")
        
        scanner.scan()
        
        p = parsePrimaryExpr()
        delref = new DelRefExpr(line,column)
        delref.expr = p
        return delref
    
    }else if tk == ast.DOT{
        scanner.scan()
        assert(scanner.curToken == ast.VAR)
        me = new MemberExpr(line,column)
        me.membername = scanner.curLex
        
        scanner.scan()
        return me
    }else if tk == ast.LPAREN{
        scanner.scan()
        val = parseExpression()
        assert(scanner.curToken == ast.RPAREN)
        
        scanner.scan()
        return val
    }else if tk == ast.LBRACKET && (prev == ast.RBRACKET || prev == ast.RPAREN) {
        return parseIndexExpr("")
    }
    else if tk == ast.FUNC
    {
        prev    = currentFunc
        closure = parseFuncDef(false,true)
        prev.closures[] = closure
        
        ClosureExpr* var = new ClosureExpr("placeholder",line,column)
        closure.receiver = var
        
        currentFunc = prev
        return var
    }else if tk == ast.VAR
    {
        var = scanner.curLex
        scanner.scan()
        return parseVarExpr(var)
    }else if tk == ast.INT
    {
        ret = new IntExpr(line,column)
        ret.literal = scanner.curLex
        
        scanner.scan()
        return ret
    }else if tk == FLOAT
    {
        val     = atof(scanner.curLex)
        scanner.scan()
        ret    = new DoubleExpr(line,column)
        ret.literal = val
        return ret
    }else if tk == STRING{
        val     = scanner.curLex
        scanner.scan()
        ret    = new StringExpr(line,column)
        
        strs[] = ret
        ret.literal = val
        return ret
    }else if tk == CHAR
    {
        val     = scanner.curLex
        scanner.scan()
        ret    = new CharExpr(line,column)
        ret.literal = val[0]
        return ret
    }else if tk == BOOL
    {
        val = 0
        if scanner.curLex == "true"
            val = 1
        scanner.scan()
        ret    = new BoolExpr(line,column)
        ret.literal = val
        return ret
    }else if tk == EMPTY
    {
        scanner.scan()
        return new NullExpr(line,column)
    }else if tk == ast.LBRACKET
    {
        scanner.scan()
        ret = new ArrayExpr(line,column)
        if scanner.curToken != ast.RBRACKET{
            while(scanner.curToken != ast.RBRACKET) {
                ret.literal[] = parseExpression()
                if scanner.curToken == ast.COMMA
                    scanner.scan()
            }
            assert(scanner.curToken == ast.RBRACKET)
            scanner.scan()
            return ret
        }
        scanner.scan()
        return ret
    }else if tk == ast.LBRACE
    {
        scanner.scan()
        ret = new MapExpr(line,column)
        if scanner.curToken != ast.RBRACE{
            while(scanner.curToken != ast.RBRACE) {
                KVExpr* kv = new KVExpr(line,column)
                kv.key    = parseExpression()
                check(scanner.curToken ==  ast.COLON)
                scanner.scan()
                kv.value  = parseExpression()
                ret.literal[] = kv
                if scanner.curToken == ast.COMMA
                    scanner.scan()
            }
            assert(scanner.curToken == ast.RBRACE)
            scanner.scan()
            return ret
        }
        scanner.scan()
        return ret
    }else if tk == NEW
    {
        scanner.scan()
        utils.debug("got new keywords:%s",scanner.curLex)
        return parseNewExpr()
    }
    return null
}

Parser::parseNewExpr()
{
    if scanner.curToken == ast.INT {
        ret = new NewExpr(line,column)
        ret.len = atoi(scanner.curLex)
        scanner.scan()
        return ret
    }
    package = ""
    name    = scanner.curLex
    
    scanner.scan()
    if scanner.curToken == ast.DOT{
        scanner.scan()
        assert(scanner.curToken == ast.VAR)
        package = name
        name = scanner.curLex
        scanner.scan()
    }
    if scanner.curToken != ast.LPAREN {
        ret = new NewExpr(line,column)
        ret.package = package
        ret.name    = name
        return ret
    }
    ret = new NewClassExpr(line,column)
    ret.package = package
    ret.name = name
    scanner.scan()
    
    while scanner.curToken != ast.RPAREN {
        ret.args[] = parseExpression()
        
        if scanner.curToken == ast.COMMA
            scanner.scan()
    }
    
    assert(scanner.curToken == ast.RPAREN)
    scanner.scan()
    return ret
}
Parser::parseVarExpr(var)
{
    package(var)
    if std.len(var != "_" && var != "__" && import,var){
        package = import[var]
    }
    match scanner.curToken{
        ast.DOT : {
            scanner.scan()
            check(scanner.curToken == ast.VAR)
            pfuncname = scanner.curLex
            
            scanner.scan()
            if  scanner.curToken == ast.LPAREN
            {
                call = parseFuncallExpr(pfuncname)
                call.is_pkgcall  = true
                
                call.package = package
               if package == "_" || package == "__"
                    call.is_extern = true
                call.is_delref = package == "__"
                
                obj
                if std.len(currentFunc.locals,var)
                    obj = currentFunc.locals[var]
                else
                    obj = currentFunc.params_var[var]
                
                if obj{
                    params = call.args
                    call.args.clear()
                    call.args[] = obj
                    call.args.insert(call.args.end(),params.begin(),params.end())
                }
                return call
            }else if scanner.curToken == ast.LBRACKET{
                IndexExpr* index = parseIndexExpr(pfuncname)
                index.is_pkgcall  = true
                index.package = package
                return index
            }else{
                mvar
                if (mvar = currentFunc.getVar(package) && mvar.structname != ""){
                    
                    mexpr = new StructMemberExpr(package,scanner.line,scanner.column)
                    
                    mexpr.var = mvar
                    mexpr.member = pfuncname
                    return mexpr
                
                }else if (mvar = getGvar(package) && mvar.structname != "") {
                    mexpr = new StructMemberExpr(package,scanner.line,scanner.column)
                    
                    mexpr.var = mvar
                    mexpr.member = pfuncname
                    return mexpr
                }
                gvar    = new VarExpr(pfuncname,line,column)
                gvar.package    = package
                gvar.is_local   = false
                return gvar
            }
        }
        ast.LPAREN:     return parseFuncallExpr(var)
        ast.LBRACKET:   return parseIndexExpr(var)
        LT : {
            Scanner::tx tx = scanner.transaction()

            expr = new VarExpr(var,line,column)
            varexpr = new VarExpr(var,line,column)
            expr.structtype = true
            expr.type = ast.U64
            expr.size = 8
            expr.isunsigned = true
            scanner.scan()
            
            if scanner.curToken == ast.VAR{
                sname = scanner.curLex
                expr.structname = sname
                scanner.scan()
                if scanner.curToken == ast.DOT{
                    scanner.scan()
                    assert(scanner.curToken == ast.VAR)
                    expr.package = sname
                    expr.structname = scanner.curLex
                    scanner.scan()
                }
                
                if scanner.curToken != GT{
                    scanner.rollback(tx)
                    return varexpr
                }
                scanner.scan()

                return expr
            }else if scanner.curToken <= ast.U64 && scanner.curToken >= ast.I8{
            
            
                expr.size = typesize[scanner.curToken]
                expr.type = scanner.curToken
                expr.isunsigned = false
                if scanner.curToken >= ast.U8 && scanner.curToken <= ast.U64
                    expr.isunsigned = true
                scanner.scan()
                if scanner.curToken == ast.MUL{
                    expr.pointer = true
                    scanner.scan()
                }
                
                
                
                if ( scanner.curToken ==  ast.COLON){
                    scanner.scan()
                    check(scanner.curToken == ast.INT,"mut be (var<i8:-int-)")
                    expr.stack = true
                    expr.stacksize = atoi(scanner.curLex)
                    scanner.scan()
                }
                check(scanner.curToken == GT,"mut be > at var expression")
                scanner.scan()
                return expr
            }
            
            scanner.rollback(tx)
            return varexpr
        }
         ast.COLON : {
            if scanner.emptyline(){
                scanner.scan()
                return new LabelExpr(var,line,column)
            }else{
                return new VarExpr(var,line,column)
            }
        }
        _ : {
            varexpr = new VarExpr(var,line,column)
            return varexpr
        }
    } 
}
Parser::parseFuncallExpr(callname)
{
    scanner.scan()
    val = new FunCallExpr(line,column)
    val.funcname = callname

    while scanner.curToken != ast.RPAREN {
        val.args[] = parseExpression()
        
        if scanner.curToken == ast.COMMA
            scanner.scan()
    }
    
    assert(scanner.curToken == ast.RPAREN)
    scanner.scan()
    return val;  
}
Parser::parseIndexExpr(varname){
    
    scanner.scan()
    val = new IndexExpr(line,column)
    val.varname = varname
    val.index = parseExpression()
    assert(scanner.curToken == ast.RBRACKET)
    
    scanner.scan()
    return val
}