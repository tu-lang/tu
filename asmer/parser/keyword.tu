use asmer.ast
use asmer.utils
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

// Pad .data offset to N-byte boundary (.balign/.align) or 2^N (.p2align).
Parser::parseBalign() {
    kind<i32> = this.scanner.curtoken
    this.check(kind == ast.KW_BALIGN || kind == ast.KW_P2ALIGN, "should be .balign/.align/.p2align")
    this.check(this.scanner.scan() == ast.TK_NUMBER, ".balign needs byte count")
    n<i32> = this.scanner.curlex.tonumber()
    if kind == ast.KW_P2ALIGN {
        this.check(n >= 0 && n < 31, ".p2align out of range")
        n = 1 << n
    }
    this.check(n > 0, ".balign align must be > 0")
    pad<i32> = (n - (this.data_size % n)) % n
    if pad > 0 {
        // Unique local name per pad (data_symbol keeps every push; map is last-wins).
        padName<string.String> = string.S(*".balign.pad")
        padSym<ast.Sym> = ast.newDataSym(padName, this.data_size)
        padSym.global = false
        padSym.addBlock(new ast.ByteBlock(ast.KW_ZERO, pad.(u64)))
        this.data_size += pad
        this.symtable.addSym(padSym)
    }
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
        tk<i32> = this.scanner.scan()
        if tk == ast.KW_LABEL {
            sym.isrel = true
            sym.str = this.scanner.curlex

            this.elf.addRel(
                string.S(*".data"),this.data_size,sym.str,elf.R_X86_64_64
            )
            this.symtable.getSym(sym.str)
            sym.addBlock(new ast.ByteBlock(ty,0.(i8)))
        }else if tk == ast.TK_NUMBER {
            v<string.String> = this.scanner.curlex
            dl<u64> = v.tonumber()
            sym.addBlock(new ast.ByteBlock(ty,dl))

            if(ty == ast.KW_ZERO){
                tysize = dl 
            }
        } else {
            this.check(tk == ast.TK_NUMBER,"should be number in quad")
        }
        this.data_size += tysize
        
        //next
        this.scanner.scan()
    }
    this.check(!this.isdata(),"not should be here in data vec")
    this.symtable.addSym(sym)
}
Parser::parseString(labelname<string.String>) {
    this.check(this.scanner.curtoken == ast.KW_STRING,"should be string")

    this.check(this.scanner.scan() == ast.TK_STRING,"should be string in parse string")
    sym<ast.Sym> = ast.newStringSym(
        labelname,this.scanner.curlex,this.data_size
    )
    this.data_size += this.scanner.curlex.len() + Pad1
    this.symtable.addSym(sym)

    //next
    this.scanner.scan()
}
