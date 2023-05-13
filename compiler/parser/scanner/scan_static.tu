use compiler.parser
use compiler.ast
use compiler.utils
use std
use string
use runtime
Eof<i32> = -1
mem ScannerStatic {
    i8* buffer  // file body
    i32 buffersize
    // token
    i32            prevToken 
    string.String* prevLex

    i32            curToken
    string.String* curLex
    string.String* filepath
    u64 parser //Parser*

    i32 line,column 
    i32 pos     //file offset
}

mem TxStatic {
    i32 txpos
    i32 txtk
    string.String* txlex
}
TxStatic::init(pos<i32>,tk<i32>,lex<string.String>){
    this.txpos = pos
    this.txtk  = tk
    this.txlex   = lex
}
func char(cn<i8>){
    return runtime.newobject(runtime.Char,cn)
}
ScannerStatic::init(filepath,parser){
    utils.debugf("parser.scanner.ScannerStatic::init() filepath:%s",filepath)
    this.pos = 0
    this.filepath = filepath
    fs = new std.File(filepath)

    if !fs.IsOpen() {
        os.die("error opening file :" + filepath )
    }
    this.parser = parser
    this.buffer = fs.ReadAllNative()
    if this.buffer == 0 {
        os.die("error read file:" + filepath)
    }
    totalsize = fs.size
    this.buffersize = *totalsize
}
ScannerStatic::transaction()
{
    return new TxStatic(this.pos,this.curToken,this.curLex)
}
ScannerStatic::rollback(x<TxStatic>)
{
    this.pos = x.txpos
    this.curToken = x.txtk
    this.curLex = x.txlex
}
ScannerStatic::next() {
    if this.pos >= this.buffersize {
        if this.pos > this.buffersize
            os.dief("[error] scanner read char over the buffer pos:%d len:%d",this.pos,std.len(this.buffer))
        this.pos += 1
        return Eof
    }
    this.column += 1
    ret = this.buffer[this.pos]
    this.pos += 1
    return ret
}
ScannerStatic::peek() {
    if this.pos >= this.buffersize {
        return Eof
    }
	return this.buffer[this.pos]
}
ScannerStatic::token(tk<i32>,lex<string.String>){
    this.curLex = lex
    this.curToken = tk
}
ScannerStatic::emptyline(){
    tx<TxStatic> = this.transaction()
    c<i8> = this.next()
    while c != Eof && c != '\n' && c !='#' && c !='/'  {
        if c != ' ' {
            this.rollback(tx)
            return false
        }
        c = this.next()
    }
    this.rollback(tx)
    return true
}

ScannerStatic::consumeLine()
{
    c<i8> = this.next()
    ret<string.String> = string.emptyS()
    while c != Eof && c != '\n' ){
        ret.putc(c)
        c = this.next()
    }
    return ret.dyn()
}

ScannerStatic::parseNumber(first<i8>)
{
    lexeme<string.String> = string.emptyS()
    lexeme.putc(first)
    isDouble<i32> = false
    cn<i8> = this.peek()
    c<i8>  = first
    
    if (c == '0' && cn == 'x'){
        while ( (cn >= 'a' && cn <= 'z') || (cn >= 'A' && cn <= 'Z') || (cn >= '0' && cn <= '9') ) {
            c<i8> = this.next()
            lexeme.putc(c)
            cn = this.peek()
        }
        return this.token(ast.INT,lexeme)
    }

    while cn >= '0' && cn <= '9' {
        if c == '.' && this.peek() != '(' 
            isDouble = true
        c = this.next()
        cn = this.peek()
        lexeme.putc(c)
    }
    if isDouble {
        return this.token(ast.FLOAT,lexeme)
    }
    return this.token(ast.INT,lexeme)
}
ScannerStatic::parseKeyword(c<i8>)
{
    lexeme<string.String> = string.emptyS()
    lexeme.putc(c)

    cn<i8> = this.peek()
    while((cn >= 'a' && cn <= 'z') || (cn >= 'A' && cn <= 'Z') || cn == '_' || (cn >= '0' && cn <= '9')){
        c = this.next()
        lexeme.putc(c)
        cn = this.peek()
    }
    //dyn 
    lex = lexeme.dyn()
    if lexeme.cmpstr(*"new") == string.Equal && cn == '('{
        return this.token(ast.VAR,lexeme)
    }
    if std.exist(lex,keywords){
        return this.token(keywords[lex],lexeme)
    } 
    p<i8> = this.peek()
    if std.exist(lex,builtins) && p == '(' {
        return this.token(ast.BUILTIN,lexeme)
    }
    return this.token(ast.VAR,lexeme)
}

ScannerStatic::parseMulOrDelref(c<i8>)
{
    cn<i8> = this.peek()
    
    if cn == '='  {
        c = this.next()
        return this.token(ast.MUL_ASSIGN, string.S(*"*="))
    }
    
    if (cn >= 'a' && cn <= 'z' || (cn >= 'A' && cn <= 'Z') || cn == '_'){
        return this.token(ast.DELREF, string.S(*"*"))
    }
    
    if cn == '\"'                  
        return this.token(ast.DELREF, string.S(*"*"))
    return this.token(ast.MUL, string.S(*"*"))
}

ScannerStatic::scan(){
    this.prevLex   = this.curLex
    this.prevToken = this.curToken

    //token
    this.get_next()
    p = this.parser
    p.line = int(this.line)
    p.column = int(this.column)
    return this.curToken
}

ScannerStatic::get_next() {
    c<i8> = this.next()
    if c == Eof
        return this.token(ast.END,string.emptyS())
blank:
    if c == ' ' || c == '\n' || c == '\r' || c == '\t'{
        while(c == ' ' || c == '\n' ||c == '\r' || c == '\t'){
            if c == '\n'{
                this.line += 1
                this.column = 0
            }
            c = this.next()
        }
        if c == Eof
            return this.token(ast.END,string.emptyS())
    }
    //TODO: support /*
    p<i8> = this.peek()
    if c == '#' || ( c == '/' && p == '/') {
comment:
        cn<i8> = this.peek()
        if c == '/'{
            c = this.next()
            cn = this.peek()
        }
        if cn == ':' {
            c = this.next()
            return this.token(ast.EXTRA,string.emptyS())
        }
        while(c != '\n' && c != Eof){
            c = this.next()
        }
        
        while(c == '\n'){
            this.line += 1
            this.column = 0
            c = this.next()
        }
        p = this.peek()
        if c == '#' || (c == '/' && p == '/') 
            goto comment
        if c == Eof
            return this.token(ast.END,string.emptyS())
        goto blank
    }
    if c >= '0' && c <= '9' {
        return this.parseNumber(c)
    }
    if  c >= 'a' && c <= 'z' || c >= 'A' && c <= 'Z' || c == '_' {
        return this.parseKeyword(c)
    }
    lexeme<string.String> = string.emptyS()
    if c == '.'{
        lexeme.putc(c)
        return this.token(ast.DOT,lexeme)
    }
    if c == ':'{
        lexeme.putc(c)
        return this.token(ast.COLON,lexeme)
    }
    if c == ';' {
        lexeme.putc(c)
        return this.token(ast.SEMICOLON,lexeme)
    }
    
    if c == '\'' {
        lit<i8> = this.next()
        rnull<u64> = &runtime.internal_null
        if lit == '\\' {
            ts = "\\"
            c = this.next()
            ts += char(c)
            //OPTIMIZE: map value is static 0
            if ts == "\\0" {
                lit = 0
            }else if specs[ts] == rnull {
                utils.panic(
                    "SyntaxError: scanner sepc [%s] character literal should surround with single-quote file:%s line:%d",
                    ts,
                    this.filepath,
                    int(this.line)
                )
            }else{
                lit = specs[ts]
            }
        }
        p<i8> = this.peek()
        if (p != '\'') {
            utils.panic("SyntaxError: a character lit should surround with single-quote c:%c file:%s\n",int(this.peek()),this.filepath)
        }
        c = this.next()
        return this.token(ast.CHAR, string.S(
            string.fromlonglong(
                lit
            )
        ))
    }
    
    if c == '\"'{
        lexeme<string.String> = string.emptyS()
        cn = this.peek()
        while(cn != '"'){
            c = this.next()
            if c == '\\'{
                lexeme.putc(c)
                c = this.next()
            }
            lexeme.putc(c)
            cn = this.peek()
        }
        c = this.next()
        return this.token(ast.STRING,lexeme)
    }
    
    if c == '[' return this.token(ast.LBRACKET,string.S(*"["))
    if c == ']' return this.token(ast.RBRACKET,string.S(*"]"))
    if c == '{' return this.token(ast.LBRACE  ,string.S(*"{"))
    if c == '}' return this.token(ast.RBRACE  ,string.S(*"}"))
    if c == '(' return this.token(ast.LPAREN  ,string.S(*"("))
    if c == ')' return this.token(ast.RPAREN  ,string.S(*")"))
    if c == ',' return this.token(ast.COMMA   ,string.S(*","))

    if c == '+'{
        cn = this.peek()
        if cn == '='{
            c = this.next()
            return this.token(ast.ADD_ASSIGN,string.S(*"+="))
        }
        return this.token(ast.ADD        ,string.S(*"+"))
    }
    if(c == '^'){
        cn = this.peek()
        if(cn == '='){
            c = this.next()
            return this.token(ast.BITXOR_ASSIGN,string.S(*"^="))
        }
        return this.token(ast.BITXOR        ,string.S(*"^"))
    }
    if c == '-'{
        cn = this.peek()
        if cn == '='{
            c = this.next()
            return this.token(ast.SUB_ASSIGN,string.S(*"-="))
        }else if cn >= '0' && cn <= '9'{
            
            return this.parseNumber('-'.(i8))
        }
        return this.token(ast.SUB,string.S(*"-"))
    }
    if c == '*'
        return this.parseMulOrDelref(c)

    if c == '/' {
        cn = this.peek()
        if (cn == '=') {
            c = this.next()
            return this.token(ast.DIV_ASSIGN, string.S(*"/="))
        }
        return this.token(ast.DIV, string.S(*"/"))
    }
    if c == '%' {
        cn = this.peek()
        if (cn == '=') {
            c = this.next()
            return this.token(ast.MOD_ASSIGN, string.S(*"%="))
        }
        return this.token(ast.MOD, string.S(*"%"))
    }
    
    if (c == '~') return this.token(ast.BITNOT,string.S(*"~"))
    if (c == '=') {
        p<i8> = this.peek()
        if (p == '=') {
            c = this.next()
            return this.token(ast.EQ, string.S(*"=="))
        }
        return this.token(ast.ASSIGN, string.S(*"="))
    }
    if (c == '!') {
        p<i8> = this.peek()
        if (p == '=') {
            c = this.next()
            return this.token(ast.NE, string.S(*"!="))
        }
        return this.token(ast.LOGNOT, string.S(*"!"))
    }
    if (c == '|') {
        p<i8> = this.peek()
        if (p == '|') {
            c = this.next()
            return this.token(ast.LOGOR, string.S(*"||"))
        }
        if (p == '=') {
            c = this.next()
            return this.token(ast.BITOR_ASSIGN, string.S(*"|="))
        }
        return this.token(ast.BITOR, string.S(*"|"))
    }
    if (c == '&') {
        p<i8> = this.peek()
        if (p == '&') {
            c = this.next()
            return this.token(ast.LOGAND, string.S(*"&&"))
        }
        if (p == '=') {
            c = this.next()
            return this.token(ast.BITAND_ASSIGN, string.S(*"&="))
        }
        return this.token(ast.BITAND, string.S(*"&"))
    }
    if (c == '>') {
        p<i8> =  this.peek() 
        if ( p == '=') {
            c = this.next()
            return this.token(ast.GE, string.S(*">="))
        }
        
        if (p == '>') {
            c = this.next()
            p = this.peek() 
            if (p == '=') {
                c = this.next()
                return this.token(ast.SHR_ASSIGN, string.S(*">>="))
            }
            return this.token(ast.SHR, string.S(*">>"))
        }

        return this.token(ast.GT, string.S(*">"))
    }
    if (c == '<') {
        p<i8> = this.peek()
        if (p == '=') {
            c = this.next()
            return this.token(ast.LE, string.S(*"<="))
        }
        if (p == '<') {
            c = this.next()
            p = this.peek() 
            if (p == '=') {
                c = this.next()
                return this.token(ast.SHL_ASSIGN, string.S(*"<<="))
            }
            return this.token(ast.SHL, string.S(*"<<"))
        }
        return this.token(ast.LT, string.S(*"<"))
    }
    
    utils.panic(
        "SyntaxError: unknown token '%d' line:%d column:%d  file:%s\n",
        int(c),int(this.line),int(this.column),this.filepath
    )
    return this.token(ast.ILLEGAL,string.S(*"invalid"))
}

ScannerStatic::priority(op)
{
    match op {
        ast.LOGOR :  return 1
        ast.LOGAND:  return 2
        ast.EQ|ast.NE|ast.GT|ast.GE|ast.LT|ast.LE :        
                     return 3
        ast.ADD|ast.SUB|ast.BITOR | ast.BITXOR:
                     return 4
        ast.MUL|ast.MOD|ast.DIV|ast.BITAND|ast.SHL|ast.SHR : 
                     return 5
        _ :          return 0
    }

}

ScannerStatic::print()
{
    this.get_next()
    while this.curToken != ast.END {
        fmt.println(ast.getTokenString(this.curToken,this.curLex))
        this.get_next()
    }

}