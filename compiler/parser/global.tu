use std
use fmt
use os
use compiler.utils
use compiler.ast
use compiler.gen
use compiler.parser.package
use string

Parser::parseEnumDef(){
    utils.debug("parser.Parser::parseEnumDef()")
    reader<scanner.ScannerStatic> = this.scanner
    reader.scan()
    
    this.expect( ast.LBRACE)
    
    reader.scan()
    defaulte = 0
    while reader.curToken != ast.RBRACE {
        gv = new gen.VarExpr(reader.curLex.dyn(),this.line,this.column)
        gv.structtype = true
        //TODO: gv.ivalue = defaulte ++
        gv.ivalue = string.tostring(defaulte)        
        this.gvars[gv.varname] = gv
        gv.is_local = false
        gv.package  = this.pkg.package
        gv.type = ast.I32
        gv.size = 4

        reader.scan()
        if reader.curToken == ast.COMMA
            reader.scan()

        defaulte += 1
    }
    reader.scan()
}

Parser::parseStructVar(varname)
{
    utils.debug("parser.Parsr::parseStructVar()")
    reader<scanner.ScannerStatic> = this.scanner
    this.expect( ast.LT )
    var = this.parseVarExpr(varname)
    varexpr = var
    this.check(varexpr.structtype)
    
    if reader.curToken == ast.ASSIGN {
        
        reader.scan()
        this.expect( ast.INT)
        varexpr.ivalue = reader.curLex.dyn()
        
        reader.scan()
    }
    this.gvars[varname] = varexpr
    varexpr.is_local = false
    varexpr.package  = this.pkg.package
}
Parser::parseFlatVar(var){
    utils.debugf("parser.Parser::parseFlatVar() varname:%s",var)
    varexpr = new gen.VarExpr(var,this.line,this.column)
    
    this.gvars[var] = varexpr
    varexpr.is_local = false
    varexpr.package  = this.pkg.package
}

Parser::parseClassFunc(var, constdef){
    utils.debugf("parser.Parser::parseClassFunc() varname:%s",var)
    reader<scanner.ScannerStatic> = this.scanner
    this.expect(  ast.COLON)
    
    reader.scan()
    this.expect( ast.COLON )
    
    reader.curToken  = ast.FUNC
   
    this.ctx = new ast.Context()

    pdefine = new ast.Class("")
    fctype  = ast.ClassFunc
    st      = null
    if compile.phase != compile.GlobalPhase{
        st = package.getStruct("",var)
        if st != null {
            fctype = ast.StructFunc
            pdefine = st
        }else{
            cls = package.getClass("",var)
            this.check(cls != null , "class not define")
            fctype = ast.ClassFunc
            pdefine = cls
        }
    }

    f = this.parseFuncDef(fctype,pdefine,null,constdef)
    this.ctx = null
    this.check(f != null)

    if fctype == ast.StructFunc && st.isasync && f.name == "poll" {
        if std.len(f.params_order_var) != 2 {
            this.check(false,"async:poll(self,ctx) signature need! :" + st.name + f.name)
        }
    }
    if fctype == ast.StructFunc {
        this.pkg.addStructFunc(var,f.name,f,st)
    } else{
        this.pkg.addClassFunc(var,f,this)
    }
    
    this.addFunc(var + f.name,f)
    return
}

Parser::parseExternClassFunc(pkgname , constdef){
    utils.debugf("parser.Parser::parseExternClassFunc() name:%s",pkgname)
    reader<scanner.ScannerStatic> = this.scanner
    this.expect( ast.DOT)
    reader.scan()
    this.expect( ast.VAR)
    clsname = reader.curLex.dyn()
    reader.scan()
    if this.getImport(pkgname) == "" {
        this.check(false,fmt.sprintf("consider import package: use %s",this.package))
    }
    this.expect(  ast.COLON )
    
    reader.scan()
    this.expect( ast.COLON )
    
    reader.curToken  = ast.FUNC
    this.ctx = new ast.Context()

    st = null
    pdefine = new ast.Class("")
    fctype  = ast.ClassFunc
    if compile.phase != compile.GlobalPhase {
        st = package.getStruct(pkgname,clsname)
        if st != null {
            fctype = ast.StructFunc
            pdefine = st
        }else{
            cls = package.getClass(pkgname,clsname)
            this.check(cls != null , "class not define "+ pkgname + "." + clsname)
            fctype = ast.ClassFunc
            pdefine = cls
        }
    }
    f = this.parseFuncDef(fctype,pdefine,null, constdef)
    this.ctx = null
    this.check(f != null)
    
    pkg = this.pkg.getPackage(pkgname)
    if fctype == ast.StructFunc {
        pkg.addStructFunc(clsname,f.name,f,st)
    }else{
        pkg.addClassFunc(clsname,f,this)
    }
    f.package = pkg
    
    this.addFunc(clsname + f.name,f)
    return
}
Parser::parseGlobalDef()
{
    reader<scanner.ScannerStatic> = this.scanner
    utils.debugf("parser.Parser::parseGlobalDef() %s line:%d\n",reader.curLex.dyn(),this.line)
    if reader.curToken != ast.VAR && reader.curToken != ast.CONST
        this.check(false,"SyntaxError: global var define invalid token:" + ast.getTokenString(reader.curToken))
    tx = reader.transaction() 
    constdef = false
    if reader.curToken == ast.CONST {
        constdef = true
        reader.scan()
    }
    var = reader.curLex.dyn()
    reader.scan()
    match reader.curToken{
        ast.COLON: return this.parseClassFunc(var , constdef)
        ast.DOT:   return this.parseExternClassFunc(var , constdef)
        // ast.LT   : return parseStructVar(var)
        // _        : return parseFlatVar(var)
        _ : {
            reader.rollback(tx)
            return this.parseGlobalAssign()
        }
    }
}

Parser::parseGlobalAssign()
{
    utils.debug("parser.Parser::parseGlobalAssign()")
    needinit = true
    expr = this.parseExpression(1)
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
                type(gen.CharExpr) : {
                    var.ivalue = ae.rhs.lit
                    if var.structtype needinit = false 
                }
                type(gen.NullExpr) : {
                    if(var.structtype) needinit = false
                }
                type(gen.ArrayExpr) : {
                    if var.structtype && var.stack {
                        arr = ae.rhs.lit
			            if var.stacksize == 1 var.stacksize = std.len(arr)
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
    var.package  = this.pkg.package
    if !needinit return false

    this.pkg.InsertInitVarExpression(assign)
} 

Parser::parseCfg(){
    reader<scanner.ScannerStatic> = this.scanner
    utils.debugf("parser.Parser::parseCfg() %s line:%d\n",reader.curLex.dyn(),this.line)
    //eat cfg 
    this.next_expect(ast.LPAREN,"cfg()")
    this.next_expect(ast.VAR,"cfg(var,..)")

    key = reader.curLex.dyn()
    this.next_expect(ast.COMMA)
    tk = reader.scan()

    if key == "static" {
        this.expect(ast.BOOL)
        if reader.curLex.dyn() == "true"
            this.cfgs.base_static =  true
        else
            this.cfgs.base_static =  false
    }else if key == "mode_static" {
        this.expect(ast.BOOL)
        if reader.curLex.dyn() == "true"
            this.pkg.cfgs.base_static =  true
        else
            this.pkg.cfgs.base_static =  false
    }else{
        this.check(false,"unkown cfg key:" + key)
    }
    this.next_expect(ast.RPAREN)
    reader.scan()
}
