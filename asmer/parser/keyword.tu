use ast
use utils
use std
use string

Parser::parseGlobal() {
    utils.debug("Parser::parseGlobal() ".(i8))
    this.check(this.scanner.curtoken == ast.KW_GLOBAL,"should be global keyword")

    //next
    this.check(this.scanner.scan() == ast.KW_LABEL,"should be label")

    labelname<string.String> = this.scanner.curlex
    sym<ast.Sym> = ast.newSym(labelname, False)
    sym.global = true
    this.symtable.addSym(sym)

    this.scanner.scan()
}
Parser::parseLabel() {
    utils.debug("Parser::parseLabel() %S".(i8),this.scanner.curlex.str())
    labelname<string.String> = this.scanner.curlex
    //next
    this.scanner.scan()
    // :
    this.check(this.scanner.curtoken == ast.TK_COLON,"missing :, should be " + labelname.dyn() + ":")

    sym<ast.Sym> = null
    tk<i32> = this.scanner.scan()
    match tk {
        ast.KW_ZERO | ast.KW_QUAD | ast.KW_LONG | ast.KW_VALUE | ast.KW_BYTE:
            return this.parseData(labelname)
        ast.KW_STRING:
            return this.parseString(labelname)
        ast.KW_LABEL:{
            sym = ast.newSym(labelname, False)
            this.symtable.addSym(sym)

            fc<ast.Function> = new ast.Function(labelname)
            this.funcs.push(fc)
            return true
        }
    }

    sym = ast.newSym(labelname, False)
    this.symtable.addSym(sym)
    fc<ast.Function> = this.parseFunction(labelname)
    this.funcs.push(fc)
}
Parser::isdata(){
    match this.scanner.curtoken {
        ast.KW_ZERO |   ast.KW_QUAD |   ast.KW_LONG |   ast.KW_VALUE |  ast.KW_BYTE :
            return true
    }
    return false
}
Parser::parseData(labelname<string.String>) {
    utils.debug("Parser::parseData() %S".(i8),labelname.str())
    sym<ast.Sym> = ast.newDataSym(labelname,this.data_size)
    while this.isdata() {
        ty<i32> = this.scanner.curtoken
        tysize<i32> = ast.typesize(this.scanner.curtoken)
        this.check(this.scanner.scan() == ast.TK_NUMBER ,"should be number in quad")

        v<string.String> = this.scanner.curlex
        dl<u64> = v.tonumber()
        sym.addBlock(new ast.ByteBlock(ty,dl))

        if(ty == ast.KW_ZERO){
            tysize = dl 
        }
        this.data_size += tysize
        
        //next
        this.scanner.scan()
    }
    this.symtable.addSym(sym)
}
Parser::parseString(labelname<string.String>) {
    this.check(this.scanner.curtoken == ast.KW_STRING,"should be string")

    this.check(this.scanner.scan() == ast.TK_STRING,"should be string in parse string")
    sym<ast.Sym> = ast.newStringSym(
        labelname,this.scanner.curlex,this.data_size
    )
    this.data_size += this.scanner.curlex.len() + 1
    this.symtable.addSym(sym)

    //next
    this.scanner.scan()
}
