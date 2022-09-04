use ast
use os
use std
use fmt
use gen

Parser::parseChainExpr(first){
    
    chainExpr = new gen.ChainExpr(line,column)
    ret  = chainExpr
    chainExpr.first = first
    if type(first) == type(gen.DelRefExpr) {
        dr = first
        check(type(dr.expr) == type(gen.StructMemberExpr))
        
        chainExpr.first = dr.expr
        dr.expr = chainExpr
        ret = dr
    }else if type(first) == type(gen.AddrExpr) {
        ae = first
        
        var = this.currentFunc.getVar(ae.package)
        check(var != null && var.structtype)
        
        sm = new gen.StructMemberExpr(ae.package,ae.line,ae.column)
        sm.member = ae.varname
        sm.var    = var
        
        chainExpr.first = sm
        ae.expr = chainExpr
        ret = ae
    }
    
    while this.ischain() { 
        match this.scanner.curToken {
            ast.DOT : {
                this.scanner.scan()
                this.expect(ast.Var)
                membername = this.scanner.curLex
                this.scanner.scan()
                fields = chainExpr.fields
                if this.scanner.curToken == ast.LPAREN {
                    mc = new gen.MemberCallExpr(this.line,this.column)
                    mc.membername = membername 
                    mc.call = this.parseFuncallExpr("")
                    //FIXME: chainExpr.fields[] = mc
                    fields[] = mc
                }else{
                    me = new gen.MemberExpr(this.line,this.column)
                    me.membername = membername
                    fileds[] = me
                    //FIXME: chainExpr.fields[] = me
                }
            }
            ast.LPAREN :   chainExpr.fields[] = parseFuncallExpr("")
            ast.LBRACKET : chainExpr.fields[] = parseIndexExpr("")
            _ : break
        }
    }
    check(std.len(chainExpr.fields),"parse chain expression,need at least 2 field")
    chainExpr.last = std.pop(chainExpr.fields)

    return ret
}

Parser::parseExpression(oldPriority)
{
    
    p = parseUnaryExpr()
    
    if this.ischain() {
        p = parseChainExpr(p)
    }
    
    if this.isassign() {
        this.check(p != null)
        if type(p) != type(gen.VarExpr) &&
            type(p) != type(gen.ChainExpr) &&
            type(p) != type(gen.IndexExpr) &&
            type(p) != type(gen.MemberExpr) &&
            type(p) != type(gen.DelRefExpr) &&
            type(p) != type(gen.StructMemberExpr)  
        {
            this.check(false,"ParseError: can not assign to " + p.name())
        }
        
        if type(p) == type(gen.StructMemberExpr) && this.currentFunc {
            sm = p
            sm.assign = true
        }
        if type(p) == type(gen.VarExpr) && this.currentFunc {
            var = p
            
            if !std.exist(var.varname,currentFunc.params_var) && !std.exist(currentFunc.locals,var.varname) {
                this.currentFunc.locals[var.varname] = var
            }
        }

        
        assignExpr = new gen.AssignExpr(line, column)
        assignExpr.opt = this.scanner.curToken
        assignExpr.lhs = p
        this.scanner.scan()
        assignExpr.rhs = parseExpression()
        return assignExpr
    }

    
    while this.isbinary() {
        currentPriority = scanner.priority(scanner.curToken)
        if (oldPriority > currentPriority)
            return p
        
        tmp = new gen.BinaryExpr(line, column)
        tmp.lhs = p
        tmp.opt = this.scanner.curToken
        this.scanner.scan()
        tmp.rhs = parseExpression(currentPriority + 1)
        p = tmp
    }
    return p
}

Parser::parseUnaryExpr()
{
    //unary expression: like -num | !var | ~var
    if this.isunary() {
        val = new gen.BinaryExpr(line,column)
        val.opt = this.scanner.curToken
        
        this.scanner.scan()
        val.lhs = parseUnaryExpr()
        return val
    }else if this.isprimary() {
        return parsePrimaryExpr()
    }
    utils.debug("parseUnaryExpr: not found token:%d-%s file:%s line:%d",scanner.curToken,scanner.curLex,filepath,line)
    return null
}

Parser::parsePrimaryExpr()
{
    tk   = this.scanner.curToken
    Token prev = scanner.prevToken
    
    if tk == ast.BUILTIN {
        builtinfunc = new gen.BuiltinFuncExpr(scanner.curLex,scanner.line,scanner.column)
        this.expect( ast.LPAREN )
        this.scanner.scan()
        
        if this.scanner.curToken == ast.MUL {
            builtinfunc.expr = parsePrimaryExpr()
        }else{
            builtinfunc.expr = parseExpression()
        }
        this.expect(ast.RPAREN)
        this.scanner.scan()
        return builtinfunc
    }
    
    if tk == ast.BITAND {
        addr = new gen.AddrExpr(scanner.line,scanner.column)
        tk = this.scanner.scan()
        if tk == ast.VAR {
            addr.varname = scanner.curLex
        }
        tk = this.scanner.scan()
        if tk == ast.DOT {
            addr.package = addr.varname
            this.scanner.scan()
            this.expect( ast.VAR )
            addr.varname = scanner.curLex
            this.scanner.scan()
        }
        return addr
    }
    if tk == ast.DELREF || tk == ast.MUL{
        utils.debug("find token delref")
        
        this.scanner.scan()
        
        p = parsePrimaryExpr()
        delref = new gen.DelRefExpr(line,column)
        delref.expr = p
        return delref
    
    }else if tk == ast.DOT{
        this.scanner.scan()
        thi.expect(ast.VAR)
        me = new gen.MemberExpr(line,column)
        me.membername = scanner.curLex
        
        this.scanner.scan()
        return me
    }else if tk == ast.LPAREN {
        this.scanner.scan()
        val = parseExpression()
        this.expect( ast.RPAREN )
        
        this.scanner.scan()
        return val
    }else if tk == ast.LBRACKET && (prev == ast.RBRACKET || prev == ast.RPAREN) {
        return parseIndexExpr("")
    }
    else if tk == ast.FUNC
    {
        prev    = this.currentFunc
        closure = parseFuncDef(false,true)
        prev.closures[] = closure
        
        var = new gen.ClosureExpr("placeholder",line,column)
        closure.receiver = var
        
        this.currentFunc = prev
        return var
    }else if tk == ast.VAR
    {
        var = scanner.curLex
        this.scanner.scan()
        return parseVarExpr(var)
    }else if tk == ast.INT
    {
        ret = new gen.IntExpr(line,column)
        ret.lit = scanner.curLex
        
        this.scanner.scan()
        return ret
    }else if tk == ast.FLOAT
    {
        val     = atof(scanner.curLex)
        this.scanner.scan()
        ret    = new gen.DoubleExpr(line,column)
        ret.lit = val
        return ret
    }else if tk == ast.STRING {
        val     = scanner.curLex
        this.scanner.scan()
        ret    = new gen.StringExpr(line,column)
        
        strs[] = ret
        ret.lit = val
        return ret
    }else if tk == ast.CHAR
    {
        val     = scanner.curLex
        this.scanner.scan()
        ret    = new gen.CharExpr(line,column)
        ret.lit = val[0]
        return ret
    }else if tk == ast.BOOL
    {
        val = 0
        if scanner.curLex == "true"
            val = 1
        this.scanner.scan()
        ret    = new gen.BoolExpr(line,column)
        ret.lit = val
        return ret
    }else if tk == ast.EMPTY
    {
        this.scanner.scan()
        return new gen.NullExpr(line,column)
    }else if tk == ast.LBRACKET
    {
        this.scanner.scan()
        ret = new gen.ArrayExpr(line,column)
        if this.scanner.curToken != ast.RBRACKET {
            while(scanner.curToken != ast.RBRACKET) {
                ret.lit[] = parseExpression()
                if this.scanner.curToken == ast.COMMA
                    this.scanner.scan()
            }
            this.expect( ast.RBRACKET )
            this.scanner.scan()
            return ret
        }
        this.scanner.scan()
        return ret
    }else if tk == ast.LBRACE
    {
        this.scanner.scan()
        ret = new gen.MapExpr(line,column)
        if this.scanner.curToken != ast.RBRACE{
            while(scanner.curToken != ast.RBRACE) {
                kv = new gen.KVExpr(line,column)
                kv.key    = parseExpression()
                this.expect( ast.COLON )
                this.scanner.scan()
                kv.value  = parseExpression()
                ret.lit[] = kv
                if this.scanner.curToken == ast.COMMA
                    this.scanner.scan()
            }
            this.expect( ast.RBRACE )
            this.scanner.scan()
            return ret
        }
        this.scanner.scan()
        return ret
    }else if tk == ast.NEW
    {
        this.scanner.scan()
        utils.debug("got new keywords:%s",scanner.curLex)
        return parseNewExpr()
    }
    return null
}

Parser::parseNewExpr()
{
    if this.scanner.curToken == ast.INT {
        ret = new gen.NewExpr(line,column)
        ret.len = atoi(scanner.curLex)
        this.scanner.scan()
        return ret
    }
    package = ""
    name    = scanner.curLex
    
    this.scanner.scan()
    if this.scanner.curToken == ast.DOT {
        this.scanner.scan()
        this.expect( ast.VAR )
        package = name
        name = scanner.curLex
        this.scanner.scan()
    }
    if this.scanner.curToken != ast.LPAREN {
        ret = new gen.NewExpr(line,column)
        ret.package = package
        ret.name    = name
        return ret
    }
    ret = new gen.NewClassExpr(line,column)
    ret.package = package
    ret.name = name
    this.scanner.scan()
    
    while this.scanner.curToken != ast.RPAREN {
        ret.args[] = parseExpression()
        
        if this.scanner.curToken == ast.COMMA
            this.scanner.scan()
    }
    
    this.expect( ast.RPAREN )
    this.scanner.scan()
    return ret
}
Parser::parseVarExpr(var)
{
    package(var)
    if std.len(var != "_" && var != "__" && import,var){
        package = import[var]
    }
    match this.scanner.curToken {
        ast.DOT : {
            this.scanner.scan()
            this.expect( ast.VAR)
            pfuncname = scanner.curLex
            
            this.scanner.scan()
            if  this.scanner.curToken == ast.LPAREN
            {
                call = parseFuncallExpr(pfuncname)
                call.is_pkgcall  = true
                
                call.package = package
               if package == "_" || package == "__"
                    call.is_extern = true
                call.is_delref = package == "__"
                
                obj = null
                if this.currentFunc != null {
                    if std.exist(var,currentFunc.locals)
                        obj = this.currentFunc.locals[var]
                    else
                        obj = this.currentFunc.params_var[var]
                }else if std.exist(var,gvars) {
                    obj = gvars[var]
                }
                
                if obj {
                    params = call.args
                    call.args = []
                    //insert obj to head
                    call.args[] = obj
                    std.merge(call.args,params)
                }
                return call
            }else if this.scanner.curToken == ast.LBRACKET {
                index = parseIndexExpr(pfuncname)
                if this.currentFunc != null  {
                    if this.currentFunc.parser.import[package] != null {
                        index.is_pkgcall  = true
                    }
                }
                index.is_pkgcall  = true
                index.package = package
                return index
            }else{
                mvar = null
                //FIXME: this.currentFunc is empty pointer
                if (currentFunc != null && ((mvar = this.currentFunc.getVar(package)) != null) && mvar.structname != ""){
                    
                    mexpr = new gen.StructMemberExpr(package,scanner.line,scanner.column)
                    
                    mexpr.var = mvar
                    mexpr.member = pfuncname
                    return mexpr
                
                }else if (mvar = getGvar(package) && mvar.structname != "") {
                    mexpr = new gen.StructMemberExpr(package,scanner.line,scanner.column)
                    
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
        ast.LT : {
            tx = scanner.transaction()

            expr = new gen.VarExpr(var,line,column)
            varexpr = new gen.VarExpr(var,line,column)
            expr.structtype = true
            expr.type = ast.U64
            expr.size = 8
            expr.isunsigned = true
            this.scanner.scan()
            
            if this.scanner.curToken == ast.VAR{
                sname = scanner.curLex
                expr.structname = sname
                this.scanner.scan()
                if this.scanner.curToken == ast.DOT{
                    this.scanner.scan()
                    this.expect( ast.VAR )
                    expr.package = sname
                    expr.structpkg = sname
                    expr.structname = scanner.curLex
                    this.scanner.scan()
                }
                
                if this.scanner.curToken != ast.GT{
                    scanner.rollback(tx)
                    return varexpr
                }
                this.scanner.scan()

                return expr
            }else if this.scanner.curToken <= ast.U64 && this.scanner.curToken >= ast.I8{
            
                expr.size = typesize[int(scanner.curToken)]
                expr.type = this.scanner.curToken
                expr.isunsigned = false
                if this.scanner.curToken >= ast.U8 && this.scanner.curToken <= ast.U64
                    expr.isunsigned = true
                this.scanner.scan()
                if this.scanner.curToken == ast.MUL{
                    expr.pointer = true
                    this.scanner.scan()
                }
                
                if ( this.scanner.curToken ==  ast.COLON){
                    this.scanner.scan()
                    this.expect( ast.INT,"mut be (var<i8:-int-)")
                    expr.stack = true
                    expr.stacksize = atoi(scanner.curLex)
                    this.scanner.scan()
                }
                this.expect( GT,"mut be > at var expression")
                this.scanner.scan()
                return expr
            }
            
            scanner.rollback(tx)
            return varexpr
        }
         ast.COLON : {
            if scanner.emptyline(){
                this.scanner.scan()
                return new gen.LabelExpr(var,line,column)
            }else{
                return new gen.VarExpr(var,line,column)
            }
        }
        _ : {
            varexpr = new gen.VarExpr(var,line,column)
            return varexpr
        }
    } 
}
Parser::parseFuncallExpr(callname)
{
    this.scanner.scan()
    val = new gen.FunCallExpr(line,column)
    val.funcname = callname

    while this.scanner.curToken != ast.RPAREN {
        val.args[] = parseExpression()
        
        if this.scanner.curToken == ast.COMMA
            this.scanner.scan()
    }
    
    this.expect( ast.RPAREN )
    this.scanner.scan()
    return val  
}
Parser::parseIndexExpr(varname){
    
    this.scanner.scan()
    val = new gen.IndexExpr(line,column)
    val.varname = varname
    val.index = parseExpression()
    this.expect( ast.RBRACKET )
    
    this.scanner.scan()
    return val
}