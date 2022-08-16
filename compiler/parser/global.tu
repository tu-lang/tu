use std
use fmt
use os
use utils
use ast

Parser::parseEnumDef(){
    
    scanner.scan()
    
    check(scanner.curToken == ast.LBRACE)
    
    scanner.scan()
    defaulte = 0
    while scanner.curToken != ast.RBRACE {
        gv = new VarExpr(scanner.curLex,line,column)
        gv.structtype = true
        //TODO: gv.ivalue = defaulte ++
        gv.ivalue = defaulte        
        gvars[gv.varname] = gv
        gv.is_local = false
        gv.package  = this.package
        gv.type = ast.I32
        gv.size = 4

        scanner.scan()
        if scanner.curToken == ast.COMMA
            scanner.scan()

        defaulte += 1
    }
    scanner.scan()
}
Parser::parseStructVar(varname)
{
    check(scanner.curToken == ast.LT )
    var = parseVarExpr(varname)
    varexpr = var
    check(varexpr.structtype)
    
    if scanner.curToken == ast.ASSIGN {
        
        scanner.scan()
        check(scanner.curToken == ast.INT)
        varexpr.ivalue = scanner.curLex
        
        scanner.scan()
    }
    gvars[varname] = varexpr
    varexpr.is_local = false
    varexpr.package  = this.package
}
Parser::parseFlatVar(var){
    varexpr = new VarExpr(var,line,column)
    
    gvars[var] = varexpr
    varexpr.is_local = false
    varexpr.package  = this.package
}

Parser::parseClassFunc(var){
    check(scanner.curToken ==  ast.COLON)
    
    scanner.scan()
    assert(scanner.curToken ==  ast.COLON)
    
    scanner.curToken  = ast.FUNC
    
    f = parseFuncDef(true)
    assert(f != null)
    
    f.clsName = var
    pkg.addClassFunc(var,f,this)
    
    this.addFunc(f.name,f)
    return
}
Parser::parseExternClassFunc(pkgname){
    check(scanner.curToken == ast.DOT)
    scanner.scan()
    check(scanner.curToken == VAR)
    clsname = scanner.curLex
    scanner.scan()
    if !std.exist(this.import,pkgname){
        check(false,fmt.sprintf("consider import package: use %s",package))
    }
    check(scanner.curToken ==  ast.COLON)
    
    scanner.scan()
    assert(scanner.curToken ==  ast.COLON)
    
    scanner.curToken  = ast.FUNC
    
    f = parseFuncDef(true)
    assert(f != null)
    
    f.clsName = clsname
    pkg = package.packages[import[pkgname]]
    pkg.addClassFunc(clsname,f,this)
    f.package = pkg
    
    this.addFunc(clsname + f.name,f)
    return
}
Parser::parseGlobalDef()
{
    if scanner.curToken != ast.VAR
        panic("SyntaxError: global var define invalid token:" + getTokenString(scanner.curToken))
    var = scanner.curLex
    tx = scanner.transaction() 
    scanner.scan()
    match scanner.curToken{
        ast.COLON: return parseClassFunc(var)
        // ast.LT   : return parseStructVar(var)
        // _        : return parseFlatVar(var)
        _ : {
            scanner.rollback(tx)
            return parseGlobalAssign()
        }
    }
}

Parser::parseGlobalAssign()
{
    bool needinit = true
    expr = parseExpression()
    if expr == null this.panic("parseGlobalAssign wrong")

    var = null
    assign = null
    match type(expr) {
        type(ast.AssignExpr) : {
            ae = expr
            if type(ae.lhs) != typeid(ast.VarExpr)) 
                this.panic("unsupport global synatix: " + expr.toString(""))
            var = ae.lhs
            assign = ae
            if (type(ae.rhs) == type(ast.IntExpr)){
                var.ivalue = ae.rhs.literal
                if var.structtype needinit = false 
            }
        }
        type(ast.VarExpr) : {
            var   = expr
            assign         = new ast.AssignExpr(this.line,this.column)
            assign.opt = ast.ASSIGN
            assign.lhs = var
            assign.rhs = new ast.NullExpr(line,column)
            if var.structtype needinit = false     
        }
        _ : this.panic("unsupport global synatix: " + expr.toString(""))
    }
    gvars[var.varname] = var
    var.is_local = false 
    var.package  = this.package
    if !needinit return

    this.pkg.InsertInitVarExpression(assign)
} 
