

Parser::parseStatementList()
{
    node = []
    p = null
    while((p = parseStatement()) != null)
    {
        node[] = p
        
        if (type(p) == type(ast.ExpressionStmt)  {
            pe = p
            if (type(pe.expr) != type(AssignExpr)  continue
            expr = pe.expr
            
            check(expr.lhs != null && expr.rhs != null)
            if type(expr.rhs == type(NewClassExpr) && type(expr.lhs) == type(VarExpr) {
                ne = expr.rhs
                obj = expr.lhs
                
                pkg = this.pkg
                if ne.package != "" {
                    package = this.import[ne.package]
                    pkg = packages[package]
                }
                check(pkg != null)
                
                call = new FunCallExpr(expr.line,expr.column)
                call.package = obj.varname
                call.funcname = "init"
                call.args = ne.args
                call.is_pkgcall = true
                params = call.args

                call.args = []
                call.args[] = obj
                //TODO: merge arr  => call.args[] = ...params
                std.merge(call.args,params)

                nd = new ExpressionStmt(call,call.line,call.column)
                node[] = nd
            }
            
        }

    }
    return node
}

Block* Parser::parseBlock()
{
    node = new ast.Block()
    scanner.scan()
    node.stmts = parseStatementList()
    
    check(scanner.curToken == ast.RBRACE)
    scanner.scan()
    return node
}

Parser::parseParameterList()
{
    node = []
    scanner.scan()
    
    if scanner.curToken == ast.RPAREN {
        scanner.scan()
        return std::move(node)
    }

    
    while scanner.curToken != ast.RPAREN {
        
        if scanner.curToken == ast.VAR
        {
            
            if currentFunc{
                var = new VarExpr(scanner.curLex,line,column)
                
                var.type = ast.U64
                var.size = 8
                var.isunsigned = true
                currentFunc.params_var[scanner.curLex] = var
                currentFunc.params_order_var[] = var

                scanner.scan()
                
                if scanner.curToken == LT{
                    var.structtype = true
                    scanner.scan()
                    if scanner.curToken == ast.VAR{
                        sname = scanner.curLex
                        var.structname = sname
                        scanner.scan()
                        if scanner.curToken == ast.DOT{
                            scanner.scan()
                            assert(scanner.curToken == ast.VAR)
                            var.package = sname
                            var.structname = scanner.curLex
                            scanner.scan()
                        }
                    }else if scanner.curToken >= ast.I8 && scanner.curToken <= ast.U64{
                    
                        Token i = scanner.curToken
                        assert(i >= ast.I8 && i <= ast.U64)
                        var.size = typesize[i]
                        var.type = i
                        var.isunsigned = false
                        if i >= ast.U8 && i <= ast.U64
                            var.isunsigned = true
                        scanner.scan()
                        if scanner.curToken == ast.MUL{
                            var.pointer = true
                            scanner.scan()
                        }

                    }else{
                        panic("unknown token " + getTokenString(scanner.curToken))
                    }
   
                    check(scanner.curToken == GT)
                    scanner.scan()
                    
                    continue
                }
                
                if scanner.curToken == ast.COMMA continue
                if scanner.curToken == ast.RPAREN continue

                
                if scanner.curToken != ast.DOT{
                    panic("SynatxError: should be , or . but got " + scanner.curLex)
                }
                
                scanner.scan()
                if scanner.curToken != ast.DOT{
                    panic("SynatxError: must be . but got :" + scanner.curLex)
                }
                
                scanner.scan()
                if scanner.curToken != ast.DOT{
                    panic("SynatxError: should be , or . but got :" + scanner.curLex)
                }
                
                currentFunc.is_variadic = true
                var.is_variadic = true
            }
            node[] = scanner.curLex
        }
        else{
            check(scanner.curToken == ast.COMMA)
        }
        
        scanner.scan()
    }
    
    assert(scanner.curToken == ast.RPAREN)
    scanner.scan()
    return move(node)
}