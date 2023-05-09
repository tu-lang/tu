use asmer.ast
use asmer.elf
use asmer.utils
use asmer.instruct
use std
use string
use os
use fmt
True<i32>  = 1
False<i32> = 0
Pad1<i32>  = 1

mem Parser {
    Scanner*        scanner
    ast.SymTable*   symtable
    elf.ElfFile*    elf
    std.Array*      funcs //Fuction*，
    string.String*  filepath 
    string.String*  filename 
    string.String*  outname 
    i64             data_size
    i32             text_size
    i32             ready
}


Parser::init(filepath,elf<elf.ElfFile>)
{
    utils.debug("Parser::init() filepath:%s".(i8),*filepath)
    this.funcs = std.array_create()
    this.elf = elf
    this.data_size = 0
    this.text_size = 0
    this.ready     = false

    this.scanner = new Scanner(filepath)
    this.symtable = new ast.SymTable()

    this.filepath = filepath

    fullname = std.pop(string.split(filepath,"/"))
    fullname = string.split(fullname,".s")
    this.filename = fullname[0]
    outname  = fullname[0] + ".o"
    this.outname = outname
}
Parser::parse() {
    this.parseLex()
    this.genInst()
    this.ready      = true
    this.text_size  = 0
    this.genInst()
}
Parser::genInst() {
    utils.debug(*"Parser::genInst() instructs collection")
    for(i<i32> = 0 ; i < this.funcs.len() ; i += 1){
        fc<ast.Function> = this.funcs.addr[i]
        sym<ast.Sym> = ast.newSym(fc.labelname,0.(i8))
        sym.addr = this.text_size
        this.symtable.addSym(sym)
        utils.debug(
            *"labelname:%S offset:%d",
            fc.labelname.str(),
            sym.addr
        )

        for(j<i32> = 0 ; j < fc.instructs.len() ; j += 1){ 
            inst<instruct.Instruct> = fc.instructs.addr[j]
            inst.gen()
        }
    }
}
Parser::parseLex()
{
    utils.debug("Parser::parseLex()".(i8))
    this.scanner.scan()
    if(this.scanner.curtoken == ast.TK_EOF) {
        os.die("[asmer] unrecognized file format :%s\n",this.filepath)
    }

    loop {
        match this.scanner.curtoken {
            ast.KW_DATA | ast.KW_TEXT:    this.scanner.scan()
            ast.KW_SIZE:{
                this.next_expect(ast.KW_LABEL,".size {?}")
                this.next_expect(ast.TK_COMMA,".size label ,")
                this.next_expect(ast.KW_LABEL,".size lable , .")
                this.next_expect(ast.TK_SUB,".size lable , .-")
                this.next_expect(ast.KW_LABEL,".size lable , .-?")
                this.scanner.scan()
            }
            ast.KW_GLOBAL: this.parseGlobal()
            ast.KW_LABEL : this.parseLabel()
            ast.TK_EOF:    break
            _:  this.check(False,"lex unkown instruct")
        }
        if this.scanner.curtoken == ast.TK_EOF
            break
    }
}
Parser::next_expect(tk<i32>,err){
    this.scanner.scan()
    return this.expect(tk,err)
}
Parser::expect(tk<i32>,err){
    if(this.scanner.curtoken == tk) return true
    err += "\nexpect:" + ast.tk_to_string(tk)
    err += "\nfound:" + string.new(this.scanner.curlex)
    err += "\t:" + ast.tk_to_string(this.scanner.curtoken)
    this.check(False,err)
    return false
}
Parser::printToken()
{
    this.scanner.scan()
    tk<i32> = this.scanner.curtoken
    str<string.String> = this.scanner.curlex
    while(tk != ast.TK_EOF){
        utils.debug(*" %d => %S\n",tk,str.inner)
        this.scanner.scan()
        tk = this.scanner.curtoken
        str = this.scanner.curlex

    }

}
Parser::check(check<i8>,err)
{
    if(check) return true
    os.dief(
        "parse: found token error token:%d:%s %s\n" + 
        "msg:%s\n" +
        "line:%d column:%d file:%s\n", 
        int(this.scanner.curtoken),
        string.new(this.scanner.curlex.inner),
        ast.tk_to_string(this.scanner.curtoken),
        err,
        int(this.scanner.line),int(this.scanner.column),this.filepath
    )
}

