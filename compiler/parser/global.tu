use std
use fmt
use os
use utils
use ast
use gen
use parser.package
use string

Parser::parseEnumDef(){
    utils.debug("parser.Parser::parseEnumDef()")
    this.scanner.scan()
    
    this.expect( ast.LBRACE)
    
    this.scanner.scan()
    defaulte = 0
    while this.scanner.curToken != ast.RBRACE {
        gv = new gen.VarExpr(this.scanner.curLex,this.line,this.column)
        gv.structtype = true
        //TODO: gv.ivalue = defaulte ++
        gv.ivalue = string.tostring(defaulte)        
        this.gvars[gv.varname] = gv
        gv.is_local = false
        gv.package  = this.package
        gv.type = ast.I32
        gv.size = 4

        this.scanner.scan()
        if this.scanner.curToken == ast.COMMA
            this.scanner.scan()

        defaulte += 1
    }
    this.scanner.scan()
}
Parser::parseStructVar(varname)
{
    utils.debug("parser.Parsr::parseStructVar()")
    this.expect( ast.LT )
    var = this.parseVarExpr(varname)
    varexpr = var
    this.check(varexpr.structtype)
    
    if this.scanner.curToken == ast.ASSIGN {
        
        this.scanner.scan()
        this.expect( ast.INT)
        varexpr.ivalue = this.scanner.curLex
        
        this.scanner.scan()
    }
    this.gvars[varname] = varexpr
    varexpr.is_local = false
    varexpr.package  = this.package
}
Parser::parseFlatVar(var){
    utils.debugf("parser.Parser::parseFlatVar() varname:%s",var)
    varexpr = new gen.VarExpr(var,this.line,this.column)
    
    this.gvars[var] = varexpr
    varexpr.is_local = false
    varexpr.package  = this.package
}

Parser::parseClassFunc(var){
    utils.debugf("parser.Parser::parseClassFunc() varname:%s",var)
    this.expect(  ast.COLON)
    
    this.scanner.scan()
    this.expect( ast.COLON )
    
    this.scanner.curToken  = ast.FUNC
    
    f = this.parseFuncDef(true,false)
    this.check(f != null)
    
    f.clsname = var
    this.pkg.addClassFunc(var,f,this)
    
    this.addFunc(var + f.name,f)
    return
}
Parser::parseExternClassFunc(pkgname){
    utils.debugf("parser.Parser::parseExternClassFunc() name:%s",pkgname)
    this.expect( ast.DOT)
    this.scanner.scan()
    this.expect( ast.VAR)
    clsname = this.scanner.curLex
    this.scanner.scan()
    if this.import[pkgname] == null {
        this.check(false,fmt.sprintf("consider import package: use %s",this.package))
    }
    this.expect(  ast.COLON )
    
    this.scanner.scan()
    this.expect( ast.COLON )
    
    this.scanner.curToken  = ast.FUNC
    
    f = this.parseFuncDef(true,false)
    this.check(f != null)
    
    f.clsname = clsname
    pkg = package.packages[this.import[pkgname]]
    pkg.addClassFunc(clsname,f,this)
    f.package = pkg
    
    this.addFunc(clsname + f.name,f)
    return
}
Parser::parseGlobalDef()
{
    utils.debugf("parser.Parser::parseGlobalDef() %s line:%d\n",this.scanner.curLex,this.line)
    if this.scanner.curToken != ast.VAR
        this.check(false,"SyntaxError: global var define invalid token:" + ast.getTokenString(this.scanner.curToken))
    var = this.scanner.curLex
    tx = this.scanner.transaction() 
    this.scanner.scan()
    match this.scanner.curToken{
        ast.COLON: return this.parseClassFunc(var)
        ast.DOT:   return this.parseExternClassFunc(var)
        // ast.LT   : return parseStructVar(var)
        // _        : return parseFlatVar(var)
        _ : {
            this.scanner.rollback(tx)
            return this.parseGlobalAssign()
        }
    }
}

Parser::parseGlobalAssign()
{
    utils.debug("parser.Parser::parseGlobalAssign()")
    needinit = true
    expr = this.parseExpression()
    if expr == null this.panic("parseGlobalAssign wrong")

    var = null
    assign = null
    match type(expr) {
        type(gen.AssignExpr) : {
            ae = expr
            if type(ae.lhs) != type(gen.VarExpr)
                this.panic("unsupport global synatix: " + expr.toString(""))
            var = ae.lhs
            assign = ae
            match type(ae.rhs) {
                type(gen.IntExpr) : {
                    var.ivalue = ae.rhs.lit
                    if var.structtype needinit = false 
                }
                type(gen.NullExpr) : {
                    if(var.structtype) needinit = false
                }
                type(gen.ArrayExpr) : {
                    if var.structtype && var.stack {
                        arr = ae.rhs.lit
                        if std.len(arr) != var.stacksize {
                            this.check(false,
                                fmt.sprintf("arr.size:%d != stacksize:%d",
                                    std.len(arr),var.stacksize
                                )
                            )
                        }
                        for i : arr {
                            if(type(i) == type(gen.IntExpr)){
                                ie = i
                                var.elements[] = ie.lit
                            }else if(type(i) == type(gen.MapExpr)){
                                me = i
                                for(ii : me.lit){
                                    ii.check(type(ii) == type(gen.IntExpr),"must be int expr in k expr")
                                    var.elements[] = ii.lit
                                }
                            }else{                            
                                i.check(false,"all arr elments should be intexpr")
                            }
                        }
                        needinit = false
                    }
                }
                type(gen.NewStructExpr) : {
                    nse = ae.rhs
                    if(var.stack){
                        var.sinit = nse
                        needinit = false
                    }
                }
        
            }
        }
        type(gen.VarExpr) : {
            var   = expr
            assign     = new gen.AssignExpr(this.line,this.column)
            assign.opt = ast.ASSIGN
            assign.lhs = var
            assign.rhs = new gen.NullExpr(this.line,this.column)
            if var.structtype needinit = false     
        }
        _ : this.panic("unsupport global synatix: " + expr.toString(""))
    }
    this.gvars[var.varname] = var
    var.is_local = false 
    var.package  = this.package
    if !needinit return false

    this.pkg.InsertInitVarExpression(assign)
} 
