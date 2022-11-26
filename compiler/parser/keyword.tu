use ast
use string
use std
use parser.package
use gen

Parser::parseClassDef()
{
    utils.debug("parser.Parser::parseClassDef() found class. start parser..")
    this.expect(ast.CLASS)
    
    this.scanner.scan()
    
    this.expect(ast.VAR)
    s = new ast.Class(this.pkg.package)
    s.found = true
    s.parser = this
    s.name  = this.scanner.curLex
    this.scanner.scan()
    
    this.expect(ast.LBRACE)

    this.scanner.scan()
    
    while this.scanner.curToken != ast.RBRACE {
        
        if this.scanner.curToken == ast.VAR{
            member = this.parseExpression()
            if type(member) == type(gen.VarExpr) {
                s.members[] = member
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
            }
        }else if this.scanner.curToken == ast.FUNC {
            f = this.parseFuncDef(true,false)
            this.check(f != null)

            f.isObj = true
            
            f.clsName = s.name
            f.structname = s.name
            s.funcs[] = f
            
            this.addFunc(f.name,f)
        }else{
            this.panic("SynatxError: token:" + ast.getTokenString(this.scanner.curToken) + " string:" + this.scanner.curLex)
        }

    }
    this.pkg.addClass(s.name,s)
    this.scanner.scan()
}

Parser::parseFuncDef(member,closure)
{
    utils.debug(
        "parser.Parser::parseFuncDef() found function: "
    )
    this.expect(ast.FUNC)
    this.scanner.scan()
    node = new ast.Function()
    node.parser = this
    node.package = this.pkg
    this.currentFunc = node
    if !closure {
        if this.hasFunc(this.scanner.curLex,false)
            this.check(false,"SyntaxError: already define function :" + this.scanner.curLex)
        node.name = this.scanner.curLex
        
        this.scanner.scan()
    }

    this.expect( ast.LPAREN)
    if member {
        var = new gen.VarExpr("this",this.line,this.column)
        node.params_var["this"] = var
        node.params_order_var[] = var
        node.params[] = "this"
    }

    params  = this.parseParameterList()
    std.merge(node.params,params)
    node.block = null
    if (this.scanner.curToken == ast.LBRACE)
        node.block = this.parseBlock(member)
    
    this.currentFunc = null
    return node
}

Parser::parseExternDef()
{
    utils.debug("parser.Parser::parseExternDef() found extern .start parser..")
    
    this.expect(ast.EXTERN)
    node     = new ast.Function()
    node.isExtern = true
    node.parser   = this

    this.scanner.scan()
    node.rettype  = this.scanner.curLex

    this.scanner.scan()
    node.name     = this.scanner.curLex
    node.block    = null

    this.scanner.scan()
    this.expect(ast.LPAREN)
    
    this.scanner.scan()
    
    if this.scanner.curToken == ast.RPAREN{
        this.scanner.scan()
        return node
    }
    while this.scanner.curToken != ast.RPAREN {
        this.scanner.scan()
    }
    
    this.expect(ast.RPAREN)
    this.scanner.scan()
    return node
}

Parser::parseExtra() {
    utils.debug("parser.Parser::parseExtra() found #: parser..")
    this.expect(ast.EXTRA)
    
    this.scanner.scan()
    
    if this.scanner.curLex == "link"{
        lines = this.scanner.consumeLine()
        lines = lines.substr(std.len(0,lines))
        
        this.links[] = lines
        return
    }
    
    this.scanner.consumeLine()
}


Parser::parseImportDef()
{
    utils.debug("parser.Parser::parseImportDef() found import.start parser..")
    this.expect(ast.USE)
    
     this.scanner.scan()
    
    this.expect(ast.VAR)
    path = this.scanner.curLex
    package = path
    multi = false
    
    this.scanner.scan()
    while(this.scanner.curToken == ast.DOT){
        
        this.scanner.scan()
        
        this.expect(ast.VAR)
        
        path += "_" + this.scanner.curLex
        package = this.scanner.curLex
        multi = true
        
        this.scanner.scan()
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
    
    this.import[package] = path

}
Parser::genClassInitFunc(clsname)
{
    utils.debugf("parser.Parser::genClassInitFunc() clsname:%s",clsname)
    f = new ast.Function()
    //set parser
    f.parser = this
    f.package = this.pkg
    if this.hasFunc(clsname + "init",false)
        this.check(false,"SyntaxError: already define function %s init",clsname)
    f.name = "init"

    var = new gen.VarExpr("this",this.line,this.column)
    f.params_var["this"] = var
    f.params_order_var[] = var
    f.params[] = "this"

    f.isObj = true
    f.clsName = clsname
    f.structname = clsname
    return f
}
