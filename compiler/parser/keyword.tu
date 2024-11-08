use compiler.ast
use string
use std
use compiler.parser.package
use compiler.gen
use compiler.compile
use compiler.utils

Parser::parseClassDef()
{
    utils.debug("parser.Parser::parseClassDef() found class. start parser..")
    reader<scanner.ScannerStatic> = this.scanner
    this.expect(ast.CLASS)
    
    reader.scan()
    
    this.expect(ast.VAR)
    s = new ast.Class(this.pkg.package)
    s.found = true
    s.parser = this
    s.name  = reader.curLex.dyn()
    this.check(utils.isUpper(s.name),"first char of class name need be Upper")
    reader.scan()

    if reader.curToken == ast.COLON  {
        utils.debug("found inherit")
        reader.scan()
        this.check(reader.curToken == ast.VAR)
        ident = reader.curLex.dyn()
        reader.scan()
        if reader.curToken == ast.DOT {
            reader.scan()
            this.check(reader.curToken == ast.VAR)
            s.father = new ast.Class(ident)
            s.father.name = reader.curLex.dyn()
            reader.scan()
        }else{
            s.father = new ast.Class(this.pkg.package)
            s.father.name = ident
        }
        s.father.parser = this
    }    
    
    this.expect(ast.LBRACE,"expect { in class define")

    reader.scan()
    
    while reader.curToken != ast.RBRACE {
        
        if reader.curToken == ast.VAR{
            member = this.parseExpression(1)
            if type(member) == type(gen.VarExpr) {
                // s.members[] = member
                se = new gen.AssignExpr(this.line,this.column)

                me = new gen.MemberExpr(this.line,this.column)
                me.varname = "this"
                me.membername = member.varname

                se.lhs = me
                se.opt = ast.ASSIGN
                se.rhs = new gen.NullExpr(this.line,this.column)
                s.initmembers[] = se
                s.membervars[] = member
            }else {
                if type(member) != type(gen.AssignExpr) {
                    this.panic("class member only support assign expr:%s",member.toString(""))
                }
                lhs = member.lhs
                if type(lhs) != type(gen.VarExpr)
                    this.panic("assign left should be var")
                var = lhs
                me = new gen.MemberExpr(var.line,var.column)
                me.varname = "this"
                me.membername = var.varname
                member.lhs = me
                s.initmembers[] = member
                s.membervars[] = var
            }
        }else if reader.curToken == ast.FUNC {
            this.ctx = new ast.Context()
            f = this.parseFuncDef(ast.ClassFunc,s,null)
            this.ctx = null
            this.check(f != null)

            s.funcs[] = f
            
            this.addFunc(s.name + f.name,f)
        }else{
            this.panic(fmt.sprintf(
                    "SynatxError: token:%s %s\n" ,
                    ast.getTokenString(reader.curToken),
                    reader.curLex.dyn()
                )
            )
        }

    }
    this.pkg.addClass(s.name,s)
    this.classes[s.name] = s
    reader.scan()
}

Parser::parseFuncDef(ft, pdefine , node)
{
    utils.debug(
        "parser.Parser::parseFuncDef() found function: "
    )
    reader<scanner.ScannerStatic> = this.scanner

    if ft != ast.AsyncFunc
        this.expect(ast.FUNC,"parse func define ,tok not fun")

    cls = pdefine
    st  = pdefine
    reader.scan()
    if node == null
        node = new ast.Function()
    node.fntype = ft

    match ft {
        ast.StructFunc : node.st = st
        ast.ClassFunc :  node.cls = cls
        ast.AsyncFunc : {
            node.asyncst = st
            node.asyncst.asyncfn = node
        }
    }    

    node.parser = this
    node.package = this.pkg
    this.currentFunc    = node
    compile.currentFunc = node
    if ft != ast.ClosureFunc  && ft != ast.AsyncFunc {
        cl = reader.curLex.dyn()
        if compile.phase == compile.GlobalPhase && this.hasFunc(cl,false)
            this.check(false,"SyntaxError: already define function :" + cl)
        node.name = cl
        
        reader.scan()
    }

    this.expect( ast.LPAREN)
    this.ctx.create()
    if ft == ast.ClassFunc || ft == ast.StructFunc || ft == ast.AsyncFunc {

        var = new gen.VarExpr("this",this.line,this.column)
        if ft == ast.StructFunc || ft == ast.AsyncFunc {
            var.structtype = true
            var.type = ast.U64
            var.size = 8
            var.isunsigned = true
            if ft == ast.AsyncFunc {
                var.structname = node.name
                var.varname = "this.0"
            }else{
                var.structpkg = pdefine.pkg
                var.structname = pdefine.name
            }
        }
        node.params_var[var.varname] = var
        node.params_order_var[] = var
    }

    params  = this.parseParameterList()

    for(it : node.params_order_var){
        this.ctx.createVar(it.varname,it)
    }
    node.block = null
    if (reader.curToken == ast.LBRACE){
        insertsuper = false
        if ft == ast.ClassFunc && pdefine.father != null {
            insertsuper = true
        }
        if compile.phase == compile.GlobalPhase {
            reader.skipblock() 
            node.block = null
        }else 
            node.block = this.parseBlock(insertsuper,true)

    }
    
    this.currentFunc = null
    compile.currentFunc = null
    this.ctx.destroy()
    return node
}

Parser::parseAsyncDef2(fcname , parethis)
{
    utils.debug(
        "parser.Parser::parseAsyncDef2() found function: "
    )
    reader<scanner.ScannerStatic> = this.scanner

    st = null
    if compile.phase == compile.GlobalPhase {
        st = new ast.Struct()
        st.name = fcname
        if parethis != null
            st.name = parethis.structname + fcname
        st.parser = this
        st.pkg  = this.pkg.package

        this.genAsyncPollMember(st,0)
        this.pkg.addAsyncStruct(st.name,st)
        this.structs[st.name] = st
    }else {
        if parethis != null
            st = this.pkg.getStruct(parethis.structname + fcname)
        else
            st = this.pkg.getStruct(fcname)
        this.check(st != null,"phase 2 st is null")
    }

    memfn = null
    if parethis != null {
        memfn = new ast.Function()
        memfn.params_var["this"] = parethis
        memfn.params_order_var[] = parethis
    }

    f = this.parseFuncDef(ast.AsyncFunc,st,memfn)
    f.name = fcname
    this.ctx = null

    if compile.phase != compile.GlobalPhase {
        if std.len(f.params_order_var) == 0 
            this.check(false,"async fn params size is 0")

        for i = 0 ;i < std.len(f.params_order_var) ; i += 1 {
            pvar = f.params_order_var[i]
            pvar.isparam = true
            if pvar.varname == "this.0" {
                f.thisvar = pvar
                continue
            }

            pvar.onmem = true
        }
        ctxvar = new gen.VarExpr("ctx.0",0,0)
        f.params_var["ctx.0"] = ctxvar
        ctxvar.isparam = true
        f.params_order_var[] = ctxvar
        f.ctxvar = ctxvar

        f = this.compileAsync(f)
    }else{
        for i = 0 ; i < std.len(f.params_order_var) ; i += 1 {
            pvar = f.params_order_var[i]
            if pvar.varname == "this.0" {
                continue
            }else {
                this.genAsyncParamMember(st,pvar)
            }
        }
    }
    if f.mcount == 0 {
        f.mcount = 1
    }
    return f
}

Parser::parseAsyncDef()
{
    utils.debug(
        "parser.Parser::parseAsyncDef() found function: "
    )
    reader<scanner.ScannerStatic> = this.scanner
    this.ctx = new ast.Context()
    this.check(reader.curToken == ast.ASYNC,"should be async")
    reader.scan()

    st = null
    isstruct = false
    structname = ""
    fcname = reader.curLex.dyn()

    parethis = null
    parentst = null
    nexc<i8> = reader.peek()
    if nexc == ':' {
        reader.scan()
        this.check(reader.curToken == ast.COLON,"need be : in async::member")
        reader.scan()
        reader.scan()

        structname = fcname
        fcname = reader.curLex.dyn()
        isstruct = true

        //parent obj
        parethis = new gen.VarExpr("this",this.line,this.column)
        parethis.structtype = true
        parethis.type = ast.U64
        parethis.size = 8
        parethis.isunsigned = true
        parethis.structname = structname

        if compile.phase != compile.GlobalPhase {
            clsd = this.pkg.getClass(structname)
            if clsd != null && clsd.found {
                parethis.structtype = false
            }else {
                parentst = this.pkg.getStruct(structname)
                if parentst != null {
                    parethis.structpkg = parentst.pkg
                    parethis.structname = parentst.name
                }
            }
        }       
    }

    f = this.parseAsyncDef2(fcname,parethis)

    // consume global phase
    if compile.phase != compile.FunctionPhase {
        return f
    }

    if isstruct {
        clsd = this.pkg.getClass(structname)
        if clsd != null && clsd.found {
            f.asyncst.asyncobj = true
            f.cls = clsd
            f.fntype = ast.ClassFunc
            
            this.pkg.addClassFunc(structname,f,this)
            this.addFunc(structname + f.name,f)
            return f
        }

        this.addFunc(structname+fcname,f)

        asyncname = f.name
        f.name = "poll"
        this.pkg.addStructFunc(structname,asyncname,f,null)
        this.pkg.addStructFunc(structname + asyncname,f.name,f,st)
    }else{
        asyncname = f.name
        f.name = "poll"
        this.pkg.addStructFunc(asyncname,f.name,f,st)
        this.addFunc(asyncname,f)
    }
}


Parser::parseExternDef()
{
    utils.debug("parser.Parser::parseExternDef() found extern .start parser..")
    reader<scanner.ScannerStatic> = this.scanner
    
    this.expect(ast.EXTERN)
    node     = new ast.Function()
    node.fntype = ast.ExternFunc
    node.parser   = this

    reader.scan()
    node.rettype  = reader.curLex.dyn()

    reader.scan()
    node.name     = reader.curLex.dyn()
    node.block    = null

    reader.scan()
    this.expect(ast.LPAREN)
    
    reader.scan()
    
    if reader.curToken == ast.RPAREN{
        reader.scan()
        return node
    }
    while reader.curToken != ast.RPAREN {
        reader.scan()
    }
    
    this.expect(ast.RPAREN)
    reader.scan()
    return node
}

Parser::parseExtra() {
    utils.debug("parser.Parser::parseExtra() found #: parser..")
    reader<scanner.ScannerStatic> = this.scanner
    this.expect(ast.EXTRA)
    
    reader.scan()
    cl = reader.curLex.dyn() 
    if cl == "link"{
        lines = reader.consumeLine()
        lines = lines.substr(0,std.len(lines))
        
        this.links[] = lines
        return
    }
    
    reader.consumeLine()
}


Parser::parseImportDef()
{
    utils.debug("parser.Parser::parseImportDef() found import.start parser..")
    reader<scanner.ScannerStatic> = this.scanner
    this.expect(ast.USE)
    
     reader.scan()
    
    this.expect(ast.VAR)
    path = reader.curLex.dyn()
    package = path
    multi = false
    
    reader.scan()
    while(reader.curToken == ast.DOT){
        
        reader.scan()
        
        this.expect(ast.VAR)
        cl = reader.curLex.dyn() 
        path += "_" + cl
        package = cl
        multi = true
        
        reader.scan()
    }
    utils.notice("import package :%s",path)
    
    if !std.exist(path,package.packages) {
        pkg = new package.Package(package,path,multi)
        package.packages[path] = pkg
        
        if !pkg.parse() {
            utils.notice("praser package :%s failed",path)
            this.check(false,"SyntaxError: package:" + path + " not exist in local or global ")
        }
    }
    utils.notice("import package :%s done",path)
    
    this.pkg.imports[package] = path

}
Parser::genClassInitFunc(clsname)
{
    utils.debugf("parser.Parser::genClassInitFunc() clsname:%s",clsname)
    f = new ast.Function()
    //set parser
    f.parser = this
    f.package = this.pkg
    if compile.phase == compile.GlobalPhase && this.hasFunc(clsname + "init",false)
        this.check(false,"SyntaxError: already define function %s init",clsname)
    f.name = "init"

    var = new gen.VarExpr("this",this.line,this.column)
    f.params_var["this"] = var
    f.params_order_var[] = var

    f.block = new gen.BlockStmt()

    return f
}
