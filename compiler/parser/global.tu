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
    pkg.addClassFunc(var,f)
    
    this.addFunc(f.name,f)
    return
}
Parser::parseGlobalDef()
{
    if scanner.curToken != ast.VAR
        panic("SyntaxError: global var define invalid token:" + getTokenString(scanner.curToken))
    var = scanner.curLex
    
    scanner.scan()
    match scanner.curToken{
        ast.LT   : return parseStructVar(var)
        ast.COLON: return parseClassFunc(var)
        _        : return parseFlatVar(var)
    }
}