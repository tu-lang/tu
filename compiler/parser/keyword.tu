use ast
use string
use std

Parser::parseClassDef()
{
    utils.debug("found class. start parser..")
    this.expect(ast.CLASS)
    
    scanner.scan()
    
    this.expect(ast.VAR)
    s = new ast.Class(this.pkg.package)
    s.parser = this
    s.name  = scanner.curLex
    scanner.scan()
    
    this.expect(ast.LBRACE)

    scanner.scan()
    
    while scanner.curToken != ast.RBRACE {
        
        if scanner.curToken == ast.VAR{
            member = parseExpression()
            if type(member) == type(gen.VarExpr) {
                s.members[] = member
            }else {
                if type(member) != type(ast.AssignExpr) {
                    this.panic("class member only support assign expr:%s",member.toString(""))
                }
                lhs = member.lhs
                if type(lhs) != type(gen.VarExpr)
                    this.panic("assign left should be var")
                var = lhs
                var.package = "this"
                var.is_local = false
                s.initmembers[] = member
            }
        }else if scanner.curToken == ast.FUNC {
            f = parseFuncDef(true)
            assert(f != null)

            f.isObj = true
            
            f.clsName = s.name
            f.structname = s.name
            s.funcs[] = f
            
            this.addFunc(f.name,f)
        }else{
            panic("SynatxError: token:" + getTokenString(scanner.curToken) + " string:" + scanner.curLex)
        }

    }
    pkg.addClass(s.name,s)
    scanner.scan()
}
Parser::parseStructDef()
{
    utils.debug("found class start parser..")
    this.expect(ast.MEM)
    scanner.scan()
    this.expect(ast.VAR)
    s = new Struct()
    s.parser = this
    s.name  = scanner.curLex
    s.pkg   = package
    scanner.scan()
    
    if scanner.curToken != ast.LBRACE {
        this.expect(  ast.COLON)
        scanner.scan()
        
        this.expect( ast.VAR)
        if (scanner.curLex == "pack" ){
            s.ispacked = true
        }
        scanner.scan()
    }
    
    this.expect( ast.LBRACE)
    scanner.scan()
    
    idx = 0
    while scanner.curToken != ast.RBRACE {
        tk  = scanner.curToken
        
        if tk == ast.VAR {
            lex = scanner.curLex 

            member = new Member()
            member.isunsigned = true
            member.isclass   = true
            
            member.structpkg  = pkg.package
            member.structname = lex
            member.structref  = null
            member.arrsize    = 1
            
            member.line = line
            member.column = column
            member.file   = filepath
            scanner.scan()
            if scanner.curToken == ast.DOT {
                scanner.scan()
                this.expect( ast.VAR)
                member.structpkg = member.structname
                member.structname = scanner.curLex
                scanner.scan()
            }
            if scanner.curToken == ast.MUL {
                member.pointer = true
                scanner.scan()
            }
            this.expect( ast.VAR)
            member.name = scanner.curLex
            s.member[] = member
            scanner.scan()
            continue
        }
        scanner.scan()
        pointer = false
        if scanner.curToken == ast.MUL {
            pointer = true
            scanner.scan()
        }
        member = parseMember(tk,idx,pointer)
        s.member[] = member
        
        while scanner.curToken == ast.COMMA {
            scanner.scan()
            member = parseMember(tk,idx,pointer)
            s.member[] = member
        }
    }
    pkg.addStruct(s.name,s)
    scanner.scan()
}
Parser::parseMember(tk,idx,pointer){
    check(tk >= ast.I8 && tk <= ast.U64)
    member = new Member()
    member.line = line
    member.column = column
    member.file  = filepath
    member.isunsigned = false
    if tk >= ast.U8 && tk <= ast.U64
        member.isunsigned = true
    member.idx    = idx 
    //FIXME: reference idx here
    idx += 1
    member.type = tk
    member.size = typesize[int(tk)]
    member.align = typesize[int(tk)]
    member.arrsize = 1

    if pointer {
        member.align = 8
        member.pointer = true
    }

    this.expect( ast.VAR)
    member.name = scanner.curLex

    scanner.scan()
    if scanner.curToken ==  ast.COLON {
        scanner.scan()
        this.expect( ast.INT)
        member.bitfield = true
        member.bitwidth = string.tonumber(scanner.curLex)
        scanner.scan()
    }else if scanner.curToken == ast.LBRACKET{
        scanner.scan()
        this.expect( ast.INT)
        member.isarr   = true
        member.arrsize = string.tonumber(scanner.curLex)
        scanner.scan()
        this.expect( ast.RBRACKET)
        scanner.scan()
    }
    return member
}

Parser::parseFuncDef(member,closure)
{
    utils.debug("found function. start parser..")
    this.expect(ast.FUNC)
    scanner.scan()
    node = new Function()
    node.parser = this
    node.package = this.pkg
    currentFunc = node

    if !closure {
        if hasFunc(scanner.curLex)
            check(false,"SyntaxError: already define function ")
        node.name = scanner.curLex
        
        scanner.scan()
    }

    this.expect( ast.LPAREN)

    if member {
        var = new VarExpr("this",line,column)
        node.params_var["this"] = var
        node.params_order_var[] = var
        node.params[] = "this"
    }

    params  = parseParameterList()
    std.merge(node.params,params)
    node.block = null
    if (scanner.curToken == ast.LBRACE)
        node.block = parseBlock(member)
    
    currentFunc = null
    return node
}

Parser::parseExternDef()
{
    utils.debug("found extern .start parser..")
    
    this.expect(ast.EXTERN)
    node     = new Function()
    node.isExtern = true
    node.parser   = this

    scanner.scan()
    node.rettype  = scanner.curLex

    scanner.scan()
    node.name     = scanner.curLex
    node.block    = null

    scanner.scan()
    this.expect(ast.LPAREN)
    
    scanner.scan()
    
    if scanner.curToken == ast.RPAREN{
        scanner.scan()
        return node
    }
    while scanner.curToken != ast.RPAREN {
        scanner.scan()
    }
    
    this.expect(ast.RPAREN)
    scanner.scan()
    return node
}

Parser::parseExtra() {
    utils.debug("found #: parser..")
    this.expect(ast.EXTRA)
    
    scanner.scan()
    
    if scanner.curLex == "link"{
        lines = scanner.consumeLine()
        lines = lines.substr(std.len(0,lines))
        
        links[] = lines
        return
    }
    
    scanner.consumeLine()
}


Parser::parseImportDef()
{
    utils.debug("found import.start parser..")
    this.expect(ast.USE)
    
     scanner.scan()
    
    this.expect(ast.VAR)
    path = scanner.curLex
    package(path)
    multi = false
    
    scanner.scan()
    while(scanner.curToken == ast.DOT){
        
        scanner.scan()
        
        this.expect(ast.VAR)
        
        path += "_" + scanner.curLex
        package = scanner.curLex
        multi = true
        
        scanner.scan()
    }

    
    if !std.exist(path,package.packages) {
        pkg = new Package(package,path,multi)
        package.packages[path] = pkg
        
        if !pkg.parse() {
            check(false,"SyntaxError: package:" + path + " not exist in local or global ")
        }
    }
    
    import[package] = path

}
Parser::genClassInitFunc(clsname)
{
    f = new ast.Function()
    //set parser
    f.parser = this
    f.package = this.pkg
    if hasFunc(clsname + "init")
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
