use compiler.ast
use os
use std
use fmt
use compiler.compile
use compiler.gen
use compiler.utils
use compiler.parser.scanner

Parser::parseChainExpr(first){
    utils.debug("parser.Parser::parseChainExpr()")
    reader<scanner.ScannerStatic> = this.scanner
    chainExpr = new gen.ChainExpr(this.line,this.column)
    ret  = chainExpr
    chainExpr.first = first
    var = null
    is_gmvar = false
    if type(first) == type(gen.DelRefExpr) {
        dr = first
        this.check(type(dr.expr) == type(gen.StructMemberExpr))
        
        chainExpr.first = dr.expr
        dr.expr = chainExpr
        ret = dr
    }else if type(first) == type(gen.AddrExpr) {
        ae = first
        
        sm = new gen.StructMemberExpr(ae.package,ae.line,ae.column)
        sm.member = ae.varname
        sm.var    = var
        
        chainExpr.first = sm
        ae.expr = chainExpr
        ret = ae
    }else if type(first) == type(gen.VarExpr) {
        var = first
        if var.package != "" {
            gv = this.getGlobalVar(var.package,var.varname)
            if (gv != null && gv.structtype){
                var = gv
                is_gmvar = true
            }
        }
    }
    
    while this.ischain() { 
        match reader.curToken {
            ast.DOT : {
                reader.scan() //eat.
                ta = null
                if reader.curToken == ast.LPAREN {
                    ta = this.parseTypeAssert(true)
                }
                this.expect(ast.VAR)
                membername = reader.curLex.dyn()
                reader.scan()
                if reader.curToken == ast.LPAREN {
                    mc = new gen.MemberCallExpr(this.line,this.column)
                    mc.membername = membername 
                    mc.call = this.parseFuncallExpr("")
                    mc.tyassert = ta
                    if is_gmvar {
                        is_gmvar = false
                        mc.obj   = var
                        chainExpr.first = mc
                    }else{
                        chainExpr.fields[] = mc
                    }
                    chainExpr.fields[] = mc
                }else{
                    if(is_gmvar){
                        is_gmvar = false
                        sm = new gen.StructMemberExpr(var.varname,var.line,var.column)
                        sm.tyassert = ta
                        sm.member = membername
                        sm.var    = var
                        chainExpr.first = sm
                    }else{
                        me = new gen.MemberExpr(this.line,this.column)
                        me.tyassert = ta
                        me.membername = membername
                        chainExpr.fields[] = me
                    }
                }
            }
            ast.LPAREN :   chainExpr.fields[] = this.parseFuncallExpr("")
            ast.LBRACKET : chainExpr.fields[] = this.parseIndexExpr("")
            _ : break
        }
    }
    if std.len(chainExpr.fields) == 0 {
        return chainExpr.first
    }
    this.check(std.len(chainExpr.fields),"parse chain expression,need at least 2 field")
    chainExpr.last = std.pop(chainExpr.fields)
    chainExpr.checkawait()
    return ret
}

Parser::parseChainExpr2(first){
    utils.debug("parser.Parser::parseChainExpr()")
    reader<scanner.ScannerStatic> = this.scanner
    chainExpr = new gen.ChainExpr(this.line,this.column)
    ret  = chainExpr
    var = null
    is_gmvar = false

    if type(first) == type(gen.DelRefExpr) {
        dr = first
        this.check(type(dr.expr) == type(gen.StructMemberExpr))
        
        chainExpr.fields[] = dr.expr
        dr.expr = chainExpr
        ret = dr
    }else if type(first) == type(gen.AddrExpr) {
        ae = first
        
        sm = new gen.StructMemberExpr(ae.package,ae.line,ae.column)
        sm.member = ae.varname
        sm.var    = var
        
        chainExpr.fields[] = sm
        ae.expr = chainExpr
        ret = ae
    }else if type(first) == type(gen.VarExpr) {
        var = first
        if var.package != "" {
            gv = this.getGlobalVar(var.package,var.varname)
            if (gv != null && gv.structtype){
                var = gv
                is_gmvar = true
            }
        }
    }
    
    while this.ischain() { 
        match reader.curToken {
            ast.DOT : {
                reader.scan() //eat.
                ta = null
                if reader.curToken == ast.LPAREN {
                    ta = this.parseTypeAssert(true)
                }
                this.expect(ast.VAR)
                membername = reader.curLex.dyn()
                reader.scan()
                if reader.curToken == ast.LPAREN {
                    mc = new gen.MemberCallExpr(this.line,this.column)
                    mc.membername = membername 
                    mc.call = this.parseFuncallExpr("")
                    mc.tyassert = ta
                    if is_gmvar {
                        is_gmvar = false
                        mc.obj   = var
                        chainExpr.fields[0] = mc
                    }else{
                        chainExpr.fields[] = mc
                    }
                    chainExpr.fields[] = mc
                }else{
                    if(is_gmvar){
                        is_gmvar = false
                        sm = new gen.StructMemberExpr(var.varname,var.line,var.column)
                        sm.tyassert = ta
                        sm.member = membername
                        sm.var    = var
                        chainExpr.fields[0] = sm
                    }else{
                        me = new gen.MemberExpr(this.line,this.column)
                        me.tyassert = ta
                        me.membername = membername
                        chainExpr.fields[] = me
                    }
                }
            }
            ast.LPAREN :   chainExpr.fields[] = this.parseFuncallExpr("")
            ast.LBRACKET : chainExpr.fields[] = this.parseIndexExpr("")
            _ : break
        }
    }
    if std.len(chainExpr.fields) == 1 {
        return chainExpr.fields[0]
    }
    chainExpr.checkawait()
    return ret
}

Parser::parseExpression(oldPriority)
{
    reader<scanner.ScannerStatic> = this.scanner
    //TODO: support default args value
    utils.debugf("parse.Parser::parseExpression() pri:%i",oldPriority)
    p = this.parseUnaryExpr()
    
    if this.ischain() {
        p = this.parseChainExpr(p)
    }
    
    if !this.ismultiassign && this.isassign() {
        this.check(p != null)
        this.lassigner(p)
        if type(p) == type(gen.StructMemberExpr) && this.currentFunc {
            sm = p
            sm.assign = true
        }
        this.newvar(p)
        
        assignExpr = new gen.AssignExpr(this.line, this.column)
        assignExpr.opt = reader.curToken
        assignExpr.lhs = p
        reader.scan()
        assignExpr.rhs = this.parseExpression(1)
        assignExpr.checkawait()
        return assignExpr
    }

    
    while this.isbinary() {
        currentPriority = reader.priority(reader.curToken)
        if (oldPriority > currentPriority)
            return p
        
        tmp = new gen.BinaryExpr(this.line, this.column)
        tmp.lhs = p
        tmp.opt = reader.curToken
        reader.scan()
        tmp.rhs = this.parseExpression(currentPriority + 1)
        tmp.checkawait()
        p = tmp
    }
    return p
}

Parser::parseUnaryExpr()
{
    reader<scanner.ScannerStatic> = this.scanner
    utils.debugf("parser.Parser::parseUnaryExpr() %s \n",
        ast.getTokenString(reader.curToken),
        // reader.curLex.dyn()
    )
    //unary expression: like -num | !var | ~var
    if this.isunary() {
        val = new gen.BinaryExpr(this.line,this.column)
        val.opt = reader.curToken
        
        reader.scan()
        val.lhs = this.parseUnaryExpr()
        if this.ischain() {
            val.lhs = this.parseChainExpr(val.lhs)
        }
        val.checkawait()
        return val
    }else if this.isprimary() {
        return this.parsePrimaryExpr()
    }
    utils.debugf(
        "parseUnaryExpr: not found token:%d-%s file:%s line:%d\n",
        int(reader.curToken),
        reader.curLex.dyn(),
        this.filepath,
        this.line
    )
    return null
}

Parser::parsePrimaryExpr()
{
    reader<scanner.ScannerStatic> = this.scanner
    utils.debugf("parser.Parser::parsePrimaryExpr() line:%d",int(reader.line))
    tk   = reader.curToken
    prev = reader.prevToken
    
    if tk == ast.BUILTIN {
        builtinfunc = new gen.BuiltinFuncExpr(reader.curLex.dyn(),int(reader.line),int(reader.column))
        this.next_expect( ast.LPAREN )
        reader.scan()
        
        if reader.curToken == ast.MUL {
            builtinfunc.expr = this.parsePrimaryExpr()
        }else{
            builtinfunc.expr = this.parseExpression(1)
        }
        this.expect(ast.RPAREN)
        reader.scan()
        return builtinfunc
    }
    
    if tk == ast.BITAND {
        addr = new gen.AddrExpr(int(reader.line),int(reader.column))
        tk = reader.scan()
        if tk == ast.VAR {
            varname = reader.curLex.dyn()
            if this.currentFunc != null {
                varexpr = this.getvar(varname)
                if varexpr != null 
                    varname = varexpr.varname
            }
            addr.varname = varname
        }
        tk = reader.scan()
        if tk == ast.DOT {
            addr.package = addr.varname
            reader.scan()
            this.expect( ast.VAR )
            addr.varname = reader.curLex.dyn()
            reader.scan()
        }
        return addr
    }
    if tk == ast.DELREF || tk == ast.MUL{
        utils.debug("find token delref")
        
        reader.scan()
        
        p = this.parsePrimaryExpr()
        delref = new gen.DelRefExpr(this.line,this.column)
        delref.expr = p
        return delref
    
    }else if tk == ast.DOT{
        reader.scan()
        this.expect(ast.VAR)
        me = new gen.MemberExpr(this.line,this.column)
        me.membername = reader.curLex.dyn()
        
        reader.scan()
        return me
    }else if tk == ast.LPAREN {
        reader.scan()
        val = this.parseExpression(1)
        this.expect( ast.RPAREN )
        
        reader.scan()
        return val
    }else if tk == ast.LBRACKET && (prev == ast.RBRACKET || prev == ast.RPAREN) {
        return this.parseIndexExpr("")
    }
    else if tk == ast.FUNC
    {
        prev    = this.currentFunc
        prev_ctx    = this.ctx

        this.ctx = new ast.Context()

        fc = new ast.Function()
        fc.parent = prev
        fc.parctx = prev_ctx

        closure = this.parseFuncDef(ast.ClosureFunc,null,fc)
        this.ctx = null
        prev.closures[] = closure
        
        var = new gen.ClosureExpr("placeholder",this.line,this.column)
        closure.receiver = var
        var.def = closure
        
        this.currentFunc    = prev
        compile.currentFunc = prev
        this.ctx = prev_ctx
        return var
    }else if tk == ast.VAR
    {
        var = reader.curLex.dyn()
        reader.scan()
        var0 = this.parseVarExpr(var)
        if type(var0) == type(gen.VarExpr) {
            ovar = this.tolevelvar(var0)
            if !var0.isdefine && var0.structtype {
                if var0.structname != ovar.structname && var0.structpkg != ovar.structpkg
                    var0.check(false,"var already define,can't redefine new one1")
                if var0.type != ovar.type
                    var0.check(false,"var already define,can't redefine new one2")
                if var0.pointer != ovar.pointer
                    var0.check(false,"var already define,can't redefine new one3")
            }
        }
        return var0
    }else if tk == ast.INT
    {
        ret = new gen.IntExpr(this.line,this.column)
        ret.lit = reader.curLex.dyn()
        reader.scan() //eat i
        if reader.curToken == ast.DOT {
            reader.scan()//eat .
            ty = this.parseTypeAssert(false)
            ret.tyassert = ty
        }
        return ret
    }else if tk == ast.FLOAT
    {
        //MENTION: use dyn 
        val<f64> = utils.strtof64(reader.curLex.str())
        reader.scan()
        ret    = new gen.FloatExpr(this.line,this.column)
        //MENTION: test bound value
        valp<u64*> = &val
        ret.lit = int(*valp)
        return ret
    }else if tk == ast.STRING {
        // fmt.vfprintf(std.STDOUT,*"1:%s\n",reader.curLex.inner)
        // fmt.vfprintf(std.STDOUT,*"2:%s\n",string.fromulonglong(reader.curLex.hash64()))
        // fmt.vfprintf(std.STDOUT,*"3:%d\n",reader.curLex.len())
        val     = reader.curLex.dyn()
        reader.scan()
        ret    = new gen.StringExpr(this.line,this.column)

        if reader.curToken == ast.DOT {
            reader.scan()
            ret.tyassert = this.parseTypeAssert(false)
        }        

        ret.lit = val
        this.add_string(ret)
        return ret
    }else if tk == ast.CHAR
    {
        val     = reader.curLex.dyn()
        reader.scan()
        ret    = new gen.CharExpr(this.line,this.column)

        if reader.curToken == ast.DOT {
            reader.scan()
            ret.tyassert = this.parseTypeAssert(false)
        }        
        ret.lit = val
        return ret
    }else if tk == ast.BOOL
    {
        val = 0
        cl = reader.curLex.dyn()
        if cl == "true"
            val = 1
        reader.scan()
        ret    = new gen.BoolExpr(this.line,this.column)
        ret.lit = val
        return ret
    }else if tk == ast.EMPTY
    {
        reader.scan()
        return new gen.NullExpr(this.line,this.column)
    }else if tk == ast.LBRACKET
    {
        reader.scan()
        ret = new gen.ArrayExpr(this.line,this.column)
        if reader.curToken != ast.RBRACKET {
            while(reader.curToken != ast.RBRACKET) {
                ret.lit[] = this.parseExpression(1)
                if reader.curToken == ast.COMMA
                    reader.scan()
            }
            this.expect( ast.RBRACKET )
            reader.scan()
            return ret
        }
        reader.scan()
        return ret
    }else if tk == ast.LBRACE
    {
        reader.scan()
        ret = new gen.MapExpr(this.line,this.column)
        if reader.curToken != ast.RBRACE{
            while(reader.curToken != ast.RBRACE) {
                kv = new gen.KVExpr(this.line,this.column)
                kv.key    = this.parseExpression(1)

                if(reader.curToken == ast.RBRACE) {
                    ret.lit[] = kv.key
                    break
                }
                if(reader.curToken == ast.COMMA){
                    reader.scan()
                    ret.lit[] = kv.key
                    continue
                }

                this.expect( ast.COLON )
                reader.scan()
                kv.value  = this.parseExpression(1)
                ret.lit[] = kv
                if reader.curToken == ast.COMMA
                    reader.scan()
            }
            this.expect( ast.RBRACE )
            reader.scan()
            return ret
        }
        reader.scan()
        return ret
    }else if tk == ast.NEW
    {
        reader.scan()
        utils.debugf("got new keywords:%s",reader.curLex.dyn())
        return this.parseNewExpr()
    }
    return null
}

Parser::parseNewExpr()
{
    utils.debug("parser.Parser::parseNewExpr()")
    reader<scanner.ScannerStatic> = this.scanner
    if reader.curToken == ast.INT {
        ret = new gen.NewExpr(this.line,this.column)
        ret.len = string.tonumber(reader.curLex.dyn())
        reader.scan()
        return ret
    }
    name    = reader.curLex.dyn()
    //new i8[3] 
    if this.isbase()
    match name {
        "i8" | "u8" | "i16" | "u16" |
        "i32"| "u32"| "i64" | "U64" : 
        {
            ret = new gen.NewExpr(this.line,this.column)
            ret.len = typesize[
                int(scanner.keywords[name])
            ]
            reader.scan()
            if reader.curToken != ast.LBRACKET
                return ret //new  i8
            // reader.scan() //eat [
            arr = this.parseExpression(1)
            if type(arr) != type(gen.ArrayExpr) this.check(false,"should be [] expression in new")
                expr = arr.lit[0]
           if type(expr) == type(gen.IntExpr) {
                i = expr
                ret.len *= string.tonumber(i.lit)
                return ret
            }
            if reader.curToken != ast.RBRACKET this.check(false,"should be ] in new expr")
            ret.arrsize = expr
            return ret
        }
    }

    package = ""
    
    reader.scan()
    if reader.curToken == ast.DOT {
        reader.scan()
        this.expect( ast.VAR )
        package = name
        name = reader.curLex.dyn()
        reader.scan()
    }
    if reader.curToken == ast.LBRACE {

        ret = new gen.NewStructExpr(this.line,this.column)
        ret.init = this.parseStructInit(package,name)
        return ret
    }
    if reader.curToken != ast.LPAREN {
        ret = new gen.NewExpr(this.line,this.column)
        ret.package = package
        ret.name    = name

        if package == "" {
            var = this.getvar(name)
            if var != null
                ret.name = var.varname
        }else{
            var = this.getvar(package)
            if var != null
                ret.package = var.varname
        }
        return ret
    }
    ret = new gen.NewClassExpr(this.line,this.column)
    ret.package = package
    ret.name = name
    reader.scan()
    
    while reader.curToken != ast.RPAREN {
        ret.args[] = this.parseExpression(1)
        
        if reader.curToken == ast.COMMA
            reader.scan()
    }
    
    this.expect( ast.RPAREN )
    reader.scan()
    return ret
}
Parser::parseVarExpr(var)
{
    utils.debugf("parser.Parser::parseVarExpr() var:%s",var)
    reader<scanner.ScannerStatic> = this.scanner
    //FIXME: the var define order
    // package(var)
    package = var
    if var != "_" && var != "__" && this.getImport(var) != "" {
        package = this.getImport(var)
    }
    match reader.curToken {
        ast.DOT : {
            reader.scan()
            ta = null
            if reader.curToken == ast.LPAREN {
                ta = this.parseTypeAssert(false)
                if reader.curToken == ast.DOT {
                    reader.scan()
                }else{
                    gvar = new gen.VarExpr(package,this.line,this.column)
                    gvar.tyassert = ta
                    gvar.is_local = false
                    return gvar
                }
            }

            if reader.curToken == ast.AWAIT {
                gvar = new gen.VarExpr(package,this.line,this.column)
                gvar.hasawait = true
                reader.scan()
                return gvar
            }
            this.expect( ast.VAR)
            pfuncname = reader.curLex.dyn()
            
            reader.scan()
            if  reader.curToken == ast.LPAREN
            {
                call = this.parseFuncallExpr(pfuncname)
                call.tyassert = ta
                call.is_pkgcall  = true
                
                call.package = package
               if package == "_" || package == "__"
                    call.is_extern = true
                call.is_delref = package == "__"
                
                obj = this.getvar(var)
                if obj != null {
                    call.package = obj.varname
                }
                
                if obj != null {
                    obj = obj.clone()
                    obj.line = call.line
                    obj.column = call.line
                    call.is_pkgcall = false
                    params = call.args
                    call.args = []
                    //insert obj to head
                    call.args[] = obj
                    std.merge(call.args,params)
                }
                return call
            }else if reader.curToken == ast.LBRACKET {
                index = this.parseIndexExpr(pfuncname)
                index.tyassert = ta

                if this.currentFunc != null  {
                    if this.currentFunc.parser.getImport(package) != "" {
                        index.is_pkgcall  = true
                    }
                    varexpr = this.getvar(package)
                    if varexpr != null 
                        package = varexpr.varname
                }
                index.is_pkgcall  = true
                index.package = package
                return index
            }else{
                mvar = null
                if this.currentFunc == null && this.getImport(var) == "" {
                    me = new gen.MemberExpr(this.line,this.column)
                    me.tyassert = ta
                    me.varname = var
                    me.membername = pfuncname
                    return me
                }else if( (mvar = this.getvar(package)) && mvar != null ){
                    if ( mvar.structtype && mvar.structname != "") {
                        mexpr = new gen.StructMemberExpr(mvar.varname,int(reader.line),int(reader.column))
                        mexpr.tyassert = ta
                        mexpr.var = mvar
                        mexpr.member = pfuncname
                        return mexpr
                    }else{
                        me = new gen.MemberExpr(this.line,this.column)
                        me.tyassert = ta
                        me.varname = mvar.varname
                        me.membername = pfuncname
                        return me
                    }            
                }
                gvar    = new gen.VarExpr(pfuncname,this.line,this.column)
                gvar.tyassert = ta
                gvar.package    = package
                gvar.is_local   = false
                return gvar
            }
        }
        ast.LPAREN:     {
            varexpr = this.getvar(var)
            if varexpr != null 
                var = varexpr.varname
            return this.parseFuncallExpr(var)
        }
        ast.LBRACKET:   {
            varexpr = this.getvar(var)
            if varexpr != null 
                var = varexpr.varname
            return this.parseIndexExpr(var)
        }
        ast.LT : {
            tx = reader.transaction()

            expr = new gen.VarExpr(var,this.line,this.column)
            varexpr = new gen.VarExpr(var,this.line,this.column)
            expr.structtype = true
            expr.type = ast.U64
            expr.size = 8
            expr.isunsigned = true
            reader.scan()
            
            if reader.curToken == ast.VAR{
                sname = reader.curLex.dyn()
                expr.structname = sname
                reader.scan()
                if reader.curToken == ast.DOT{
                    reader.scan()
                    this.expect( ast.VAR )
                    expr.structpkg = sname
                    expr.structname = reader.curLex.dyn()
                    reader.scan()
                }else {
                    expr.structpkg = this.pkg.package
                }
                if ( reader.curToken ==  ast.COLON){
                    this.parseVarStack(expr)
                }                
                if reader.curToken != ast.GT{
                    reader.rollback(tx)
                    return varexpr
                }
                reader.scan()

                return expr
            }else if reader.curToken <= ast.F64 && reader.curToken >= ast.I8{
            
                expr.size = typesize[int(reader.curToken)]
                expr.type = reader.curToken
                expr.isunsigned = ast.type_isunsigned(reader.curToken)
                reader.scan()
                if reader.curToken == ast.MUL{
                    expr.pointer = true
                    reader.scan()
                }
                
                if ( reader.curToken ==  ast.COLON){
                    this.parseVarStack(expr)
                }
                this.expect( ast.GT,"mut be > at var expression")
                reader.scan()
                return expr
            }
            
            reader.rollback(tx)
            return varexpr
        }
         ast.COLON : {
            if reader.emptyline(){
                reader.scan()
                return new gen.LabelExpr(var,this.line,this.column)
            }else{
                return new gen.VarExpr(var,this.line,this.column)
            }
        }
        _ : {
            varexpr = new gen.VarExpr(var,this.line,this.column)
            return varexpr
        }
    } 
}
Parser::parseFuncallExpr(callname)
{
    utils.debug("parser.Parser::parseFuncallExpr() callname:%s",callname)
    reader<scanner.ScannerStatic> = this.scanner
    reader.scan()
    val = new gen.FunCallExpr(this.line,this.column)
    val.p = this
    val.funcname = callname

    while reader.curToken != ast.RPAREN {
        val.args[] = this.parseExpression(1)
        
        if reader.curToken == ast.COMMA
            reader.scan()
    }
    
    this.expect( ast.RPAREN )
    reader.scan()

    if reader.curToken == ast.DOT {
        tx = reader.transaction()
        reader.scan()
        if reader.curToken == ast.AWAIT {
            val.hasawait = true
            reader.scan()
        }else{
            reader.rollback(tx)
        }
    }
    return val  
}
Parser::parseIndexExpr(varname){
    utils.debugf("parser.Parser::parseIndexExpr() varname:%s",varname) 
    reader<scanner.ScannerStatic> = this.scanner
    reader.scan()
    val = new gen.IndexExpr(this.line,this.column)
    val.varname = varname
    val.index = this.parseExpression(1)
    this.expect( ast.RBRACKET )
    
    reader.scan()
    return val
}
