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
            f = this.parseFuncDef(ClassFunc,s)
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

Parser::parseFuncDef(ft, pdefine)
{
    utils.debug(
        "parser.Parser::parseFuncDef() found function: "
    )
    reader<scanner.ScannerStatic> = this.scanner
    isasync = false
    if reader.curToken == ast.ASYNC {
        isasync = true
        reader.scan()
    }
    this.expect(ast.FUNC)
    reader.scan()
    node = new ast.Function()

    match ft {
        StructFunc : {
            node.isMem = true
            node.isObj = false
            if isasync {
                node.clsname = reader.curLex.dyn()
            }else {
                node.clsname = pdefine.name
            }
        }
        ClassFunc :{
            node.isObj = true
            node.structname = pdefine.name
            node.clsname = pdefine.name
        }
    }    
    node.isasync = isasync

    node.parser = this
    node.package = this.pkg
    this.currentFunc    = node
    compile.currentFunc = node
    if ft != ClosureFunc {
        cl = reader.curLex.dyn()
        if compile.phase == compile.GlobalPhase && this.hasFunc(cl,false)
            this.check(false,"SyntaxError: already define function :" + cl)
        node.name = cl
        
        reader.scan()
    }

    this.expect( ast.LPAREN)
    this.ctx.create()
    if ft == ClassFunc || ft == StructFunc {

        var = new gen.VarExpr("this",this.line,this.column)
        if ft == StructFunc {
            var.structtype = true
            var.type = ast.U64
            var.size = 8
            var.isunsigned = true
            if isasync {
                var.structname = node.name
            }else{
                var.structpkg = pdefine.pkg
                var.structname = pdefine.name
            }
        }
        node.params_var["this"] = var
        node.params_order_var[] = var
    }

    params  = this.parseParameterList()

    for(it : node.params_order_var){
        this.ctx.createVar(it.varname,it)
    }
    node.block = null
    if (reader.curToken == ast.LBRACE){
        insertsuper = false
        if ft == ClassFunc && pdefine.father != null {
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

Parser::parseAsyncDef()
{
    utils.debug(
        "parser.Parser::parseAsyncDef() found function: "
    )
    this.ctx = new ast.Context()
    f = this.parseFuncDef(StructFunc,null)
    this.ctx = null

    if compile.phase != compile.GlobalPhase {
        f = this.compileAsync(f)
        f.state = this.pkg.getStruct(f.name)
        if f.state == null {
            this.check(false,"async state is null")
        }
    }else{
        s = new ast.Struct()
        s.name = f.name
        s.parser = this
        this.genAsyncPollMember(s,0)
        this.pkg.addAsyncStruct(s.name,s)
        this.structs[s.name] = s
        f.state = s
    }
    structname = f.name
    f.name = "poll"
    this.pkg.addClassFunc(structname,f,this)
    this.addFunc(structname,f)
}


Parser::parseExternDef()
{
    utils.debug("parser.Parser::parseExternDef() found extern .start parser..")
    reader<scanner.ScannerStatic> = this.scanner
    
    this.expect(ast.EXTERN)
    node     = new ast.Function()
    node.isExtern = true
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

    f.isObj = true
    f.clsname = clsname
    f.structname = clsname
    return f
}
