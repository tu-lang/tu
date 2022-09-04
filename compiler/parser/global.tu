use std
use fmt
use os
use utils
use ast
use gen

Parser::parseEnumDef(){
    
    this.scanner.scan()
    
    this.expect( ast.LBRACE)
    
    this.scanner.scan()
    defaulte = 0
    while this.scanner.curToken != ast.RBRACE {
        gv = new VarExpr(scanner.curLex,line,column)
        gv.structtype = true
        //TODO: gv.ivalue = defaulte ++
        gv.ivalue = defaulte        
        gvars[gv.varname] = gv
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
    this.expect( ast.LT )
    var = parseVarExpr(varname)
    varexpr = var
    check(varexpr.structtype)
    
    if this.scanner.curToken == ast.ASSIGN {
        
        this.scanner.scan()
        this.expect( ast.INT)
        varexpr.ivalue = scanner.curLex
        
        this.scanner.scan()
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
    this.expect(  ast.COLON)
    
    this.scanner.scan()
    this.expect( ast.COLON )
    
    this.scanner.curToken  = ast.FUNC
    
    f = parseFuncDef(true)
    this.check(f != null)
    
    f.clsName = var
    pkg.addClassFunc(var,f,this)
    
    this.addFunc(f.name,f)
    return
}
Parser::parseExternClassFunc(pkgname){
    this.expect( ast.DOT)
    this.scanner.scan()
    this.expect( ast.VAR)
    clsname = scanner.curLex
    this.scanner.scan()
    if !std.exist(this.import,pkgname){
        check(false,fmt.sprintf("consider import package: use %s",package))
    }
    this.expect(  ast.COLON )
    
    this.scanner.scan()
    this.expect( ast.COLON )
    
    this.scanner.curToken  = ast.FUNC
    
    f = parseFuncDef(true)
    this.check(f != null)
    
    f.clsName = clsname
    pkg = package.packages[import[pkgname]]
    pkg.addClassFunc(clsname,f,this)
    f.package = pkg
    
    this.addFunc(clsname + f.name,f)
    return
}
Parser::parseGlobalDef()
{
    if this.scanner.curToken != ast.VAR
        this.panic("SyntaxError: global var define invalid token:" + getTokenString(scanner.curToken))
    var = scanner.curLex
    tx = scanner.transaction() 
    this.scanner.scan()
    match this.scanner.curToken{
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
            if type(ae.lhs) != typeid(gen.VarExpr)
                this.panic("unsupport global synatix: " + expr.toString(""))
            var = ae.lhs
            assign = ae
            if (type(ae.rhs) == type(gen.IntExpr)){
                var.ivalue = ae.rhs.lit
                if var.structtype needinit = false 
            }
        }
        type(gen.VarExpr) : {
            var   = expr
            assign     = new ast.AssignExpr(this.line,this.column)
            assign.opt = ast.ASSIGN
            assign.lhs = var
            assign.rhs = new gen.NullExpr(line,column)
            if var.structtype needinit = false     
        }
        _ : this.panic("unsupport global synatix: " + expr.toString(""))
    }
    gvars[var.varname] = var
    var.is_local = false 
    var.package  = this.package
    if !needinit return false

    this.pkg.InsertInitVarExpression(assign)
} 
