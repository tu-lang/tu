
use std
use fmt
use ast
use string
use gen
use utils

Parser::parseBlock(member)
{
    utils.debug("parser.Parser::parseBlock()")
    node = new ast.Block()
    this.scanner.scan()
    if member {
        stmt = this.genSuperInitStmt(this.currentFunc)
        node.stmts[] = stmt
    }
    stmts = []
    while( (p = this.parseStatement()) != null )
    {
        stmts[] = p
    }
    
    std.merge(node.stmts,stmts)

    this.expect(ast.RBRACE,"parse block ")
    this.scanner.scan()
    return node
}

Parser::parseParameterList()
{
    utils.debug("parser.Parser.parseParameterList()")
    node = []
    this.scanner.scan()
    
    if this.scanner.curToken == ast.RPAREN {
        this.scanner.scan()
        return node
    }

    while this.scanner.curToken != ast.RPAREN 
    {
        if this.scanner.curToken == ast.VAR
        {
            if this.currentFunc {
                var = new gen.VarExpr(this.scanner.curLex,this.line,this.column)
                
                var.type = ast.U64
                var.size = 8
                var.isunsigned = true
                this.currentFunc.params_var[this.scanner.curLex] = var
                this.currentFunc.params_order_var[] = var

                this.scanner.scan()
                
                if this.scanner.curToken == ast.LT {
                    var.structtype = true
                    this.scanner.scan()
                    if this.scanner.curToken == ast.VAR {
                        sname = this.scanner.curLex
                        var.structname = sname
                        this.scanner.scan()
                        if this.scanner.curToken == ast.DOT {
                            this.scanner.scan()
                            this.expect(ast.VAR)
                            var.structpkg = sname
                            var.structname = this.scanner.curLex
                            this.scanner.scan()
                        }
                    }else if this.scanner.curToken >= ast.I8 && this.scanner.curToken <= ast.U64{
                    
                        i = this.scanner.curToken
                        this.check(i >= ast.I8 && i <= ast.U64)
                        var.size = typesize[int(i)]
                        var.type = i
                        var.isunsigned = ast.type_isunsigned(i)
                        this.scanner.scan()
                        if this.scanner.curToken == ast.MUL {
                            var.pointer = true
                            this.scanner.scan()
                        }
                    }else{
                        this.panic("unknown token " + ast.getTokenString(this.scanner.curToken))
                    }
   
                    this.expect(ast.GT )
                    this.scanner.scan()
                    
                    // continue
                }
                
                if this.scanner.curToken == ast.COMMA continue
                if this.scanner.curToken == ast.RPAREN continue

                
                if this.scanner.curToken != ast.DOT {
                    this.panic("SynatxError: should be , or . but got " + this.scanner.curLex)
                }
                
                this.scanner.scan()
                if this.scanner.curToken != ast.DOT {
                    this.panic("SynatxError: must be . but got :" + this.scanner.curLex)
                }
                
                this.scanner.scan()
                if this.scanner.curToken != ast.DOT{
                    this.panic("SynatxError: should be , or . but got :" + this.scanner.curLex)
                }
                
                this.currentFunc.is_variadic = true
                var.is_variadic = true
            }
            node[] = this.scanner.curLex
        }
        else{
            this.expect( ast.COMMA )
        }
        
        this.scanner.scan()
    }
    
    this.expect( ast.RPAREN )
    this.scanner.scan()
    return node
}

Parser::genSuperInitStmt(f){
    utils.debug("parser.Parser.genSuperInitStmt()")
    if this.import["runtime"] != null {
        this.import["runtime"] = "runtime"
    }
    ass = new gen.AssignExpr(this.line,this.column)
    ass.opt = ast.ASSIGN
    lhs = new gen.VarExpr("super",this.line,this.column)
    f.locals[lhs.varname] = lhs

    rhs = new gen.FunCallExpr(this.line,this.column)
    rhs.package = "runtime"
    rhs.funcname = "object_parent_get"
    var = new gen.VarExpr("this",this.line,this.column)
    rhs.args[] = var
    rhs.is_pkgcall = true
    ass.lhs = lhs
    ass.rhs = rhs
    return ass
}