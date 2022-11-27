use parser
use ast
use utils
use std
use string

class Scanner {
    fs      // std.File
    buffer  // file body
    pos     //file offset

    // token
    prevToken 
    prevLex
    curToken
    curLex

    parser //Parser*

    line
    column 

}

class Tx {
    txpos = pos 
    txtk  = tk
    txlex = lex
    func init(pos,tk,lex){}
}

Scanner::init(filepath,parser){
    utils.debugf("parser.scanner.Scanner::init() filepath:%s",filepath)
    this.fs = new std.File(filepath)
    this.pos = 0

    if !this.fs.IsOpen() {
        os.die("error opening file :" + filepath )
    }
    this.parser = parser
    //TODO:
    this.buffer = this.fs.ReadAll()
}
Scanner::transaction()
{
    return new Tx(this.pos,this.curToken,this.curLex)
}
Scanner::rollback(x)
{
    this.pos = x.txpos
    this.curToken = x.txtk
    this.curLex = x.txlex
}
Scanner::next() {
    if this.pos >= std.len(this.buffer) {
        if this.pos > std.len(this.buffer)
            os.dief("[error] scanner read char over the buffer pos:%d len:%d",this.pos,std.len(this.buffer))
        this.pos += 1
        return EOF
    }
    this.column += 1
    ret = this.buffer[this.pos]
    this.pos += 1
    return ret
}
Scanner::peek() {
    if this.pos >= std.len(this.buffer) {
        return EOF
    }
	return this.buffer[this.pos]
}
Scanner::emptyline(){
    tx = this.transaction()
    c = this.next()
    while c != EOF && c != '\n' && c !='#' && c !='/'  {
        if c != ' ' {
            this.rollback(tx)
            return false
        }
        c = this.next()
    }
    this.rollback(tx)
    return true
}

Scanner::consumeLine()
{
    c = this.next()
    ret = ""
    while c != ast.EOF && c != '\n' ){
        ret += c
        c = this.next()
    }
    return ret
}

Scanner::parseNumber(first)
{
    lexeme = string.tostring(first)
    isDouble = false
    cn = this.peek()
    c  = first
    
    if (c == '0' && cn == 'x'){
        while ( (cn >= 'a' && cn <= 'z') || (cn >= 'A' && cn <= 'Z') || (cn >= '0' && cn <= '9') ) {
            c = this.next()
            lexeme += c
            cn = this.peek()
        }
        return this.token(ast.INT,lexeme)
    }
    

    while cn >= '0' && cn <= '9' {
        if c == '.' && this.peek() != '(' 
            isDouble = true
        c = this.next()
        cn = this.peek()
        lexeme += c
    }
    if !isDouble return this.token(ast.INT,lexeme)
    else         return this.token(ast.FLOAT,lexeme)
}
Scanner::parseKeyword(c)
{
    lexeme = string.tostring(c)

    cn = this.peek()
    while((cn >= 'a' && cn <= 'z') || (cn >= 'A' && cn <= 'Z') || cn == '_' || (cn >= '0' && cn <= '9')){
        c = this.next()
        lexeme += c
        cn = this.peek()
    }
    
    if lexeme == "new" && cn == '('{
        return this.token(ast.VAR,lexeme)
    }
    if std.exist(lexeme,keywords){
        return this.token(keywords[lexeme],lexeme)
    } 
    if std.exist(lexeme,builtins) && this.peek() == '(' {
        return this.token(ast.BUILTIN,lexeme)
    }

    return this.token(ast.VAR,lexeme)
}

Scanner::parseMulOrDelref(c)
{
    cn = this.peek()
    
    if cn == '='  {
        c = this.next()
        return this.token(ast.MUL_ASSIGN, "*=")
    }
    
    if (cn >= 'a' && cn <= 'z' || (cn >= 'A' && cn <= 'Z')){
        return this.token(ast.DELREF, "*")
    }
    
    if cn == '\"'                  
        return this.token(ast.DELREF, "*")
    return this.token(ast.MUL, "*")
}

Scanner::token(tk,lex){
    this.curLex = lex
    this.curToken = tk
}
Scanner::scan(){
    this.prevLex   = this.curLex
    this.prevToken = this.curToken

    //token
    this.get_next()

    p = this.parser
    p.line = this.line
    p.column = this.column
    return this.curToken
}

Scanner::get_next() {
    c = this.next()
    if c == EOF
        return this.token(ast.END,"")
    blank:
    if c == ' ' || c == '\n' || c == '\r' || c == '\t'{
        while(c == ' ' || c == '\n' ||c == '\r' || c == '\t'){
            if c == '\n'{
                this.line += 1
                this.column = 0
            }
            c = this.next()
        }
        if c == EOF
            return this.token(ast.END,"")
    }
    //TODO: support /*
    if c == '#' || ( c == '/' && this.peek() == '/') {
        comment:
        cn = this.peek()
        if c == '/'{
            c = this.next()
            cn = this.peek()
        }
        if cn == ':' {
            c = this.next()
            return this.token(ast.EXTRA,"")
        }
        while(c != '\n' && c != EOF){
            c = this.next()
        }
        
        while(c == '\n'){
            this.line += 1
            this.column = 0
            c = this.next()
        }
        if c == '#' || (c == '/' && this.peek()== '/') 
            goto comment
        if c == EOF
            return this.token(ast.END,"")
        goto blank
    }
    if c >= '0' && c <= '9' {
        return this.parseNumber(c)
    }
    if  c >= 'a' && c <= 'z' || c >= 'A' && c <= 'Z' || c == '_' {
        return this.parseKeyword(c)
    }
    if c == '.'{
        lexeme = string.tostring(c)
        return this.token(ast.DOT,lexeme)
    }
    if c == ':'{
        lexeme = string.tostring(c)
        return this.token(ast.COLON,lexeme)
    }
    if c == ';' {
        lexeme = string.tostring(c)
        return this.token(ast.SEMICOLON,lexeme)
    }
    
    if c == '\'' {
        lexeme = string.tostring(this.next())
        lit = lexeme[0]
        if lit == '\\' {
            lexeme += this.next()
            //OPTIMIZE: char(0) == int(0) = null(0)
            if lexeme != "\\0" && specs[lexeme] == null {
                utils.panic(
                    "SyntaxError: sepc [%s] character literal should surround with single-quote file:%s line:%d",
                    lexeme,
                    this.parser.filepath,
                    this.line
                )
            }
            lit = specs[lexeme]
        }
        if (this.peek() != '\'') {
            utils.panic("SyntaxError: a character lit should surround with single-quote c:%c file:%s\n",this.peek(),this.parser.filepath)
        }
        c = this.next()
        return this.token(ast.CHAR, string.tostring(lexeme))
    }
    
    if c == '\"'{
        lexeme = ""
        cn = this.peek()
        while(cn != '"'){
            c = this.next()
            if c == '\\'{
                lexeme += c
                c = this.next()
            }
            lexeme += c
            cn = this.peek()
        }
        c = this.next()
        return this.token(ast.STRING,lexeme)
    }
    
    if c == '[' return this.token(ast.LBRACKET,"[")
    if c == ']' return this.token(ast.RBRACKET,"]")
    if c == '{' return this.token(ast.LBRACE  ,"{")
    if c == '}' return this.token(ast.RBRACE  ,"}")
    if c == '(' return this.token(ast.LPAREN  ,"(")
    if c == ')' return this.token(ast.RPAREN  ,")")
    if c == ',' return this.token(ast.COMMA   ,",")

    if c == '+'{
        cn = this.peek()
        if cn == '='{
            c = this.next()
            return this.token(ast.ADD_ASSIGN,"+=")
        }
        return this.token(ast.ADD        ,"+")
    }
    if(c == '^'){
        cn = this.peek()
        if(cn == '='){
            c = this.next()
            return this.token(ast.BITXOR_ASSIGN,"^=")
        }
        return this.token(ast.BITXOR        ,"^")
    }
    if c == '-'{
        cn = this.peek()
        if cn == '='{
            c = this.next()
            return this.token(ast.SUB_ASSIGN,"-=")
        }else if cn >= '0' && cn <= '9'{
            
            return this.parseNumber('-')
        }
        return this.token(ast.SUB,"-")
    }
    if c == '*'
        return this.parseMulOrDelref(c)

    if c == '/' {
        cn = this.peek()
        if (cn == '=') {
            c = this.next()
            return this.token(ast.DIV_ASSIGN, "/=")
        }
        return this.token(ast.DIV, "/")
    }
    if c == '%' {
        cn = this.peek()
        if (cn == '=') {
            c = this.next()
            return this.token(ast.MOD_ASSIGN, "%=")
        }
        return this.token(ast.MOD, "%")
    }
    
    if (c == '~') return this.token(ast.BITNOT,"~")
    if (c == '=') {
        if (this.peek() == '=') {
            c = this.next()
            return this.token(ast.EQ, "==")
        }
        return this.token(ast.ASSIGN, "=")
    }
    if (c == '!') {
        if (this.peek() == '=') {
            c = this.next()
            return this.token(ast.NE, "!=")
        }
        return this.token(ast.LOGNOT, "!")
    }
    if (c == '|') {
        if (this.peek() == '|') {
            c = this.next()
            return this.token(ast.LOGOR, "||")
        }
        if (this.peek() == '=') {
            c = this.next()
            return this.token(ast.BITOR_ASSIGN, "|=")
        }
        return this.token(ast.BITOR, "|")
    }
    if (c == '&') {
        if (this.peek() == '&') {
            c = this.next()
            return this.token(ast.LOGAND, "&&")
        }
        if (this.peek() == '=') {
            c = this.next()
            return this.token(ast.BITAND_ASSIGN, "&=")
        }
        return this.token(ast.BITAND, "&")
    }
    if (c == '>') {
        
        if (this.peek() == '=') {
            c = this.next()
            return this.token(ast.GE, ">=")
        }
        
        if (this.peek() == '>') {
            c = this.next()
            
            if (this.peek() == '=') {
                c = this.next()
                return this.token(ast.SHR_ASSIGN, ">>=")
            }
            return this.token(ast.SHR, ">>")
        }

        return this.token(ast.GT, ">")
    }
    if (c == '<') {
        if (this.peek() == '=') {
            c = this.next()
            return this.token(ast.LE, "<=")
        }
        if (this.peek() == '<') {
            c = this.next()
            
            if (this.peek() == '=') {
                c = this.next()
                return this.token(ast.SHL_ASSIGN, "<<=")
            }
            return this.token(ast.SHL, "<<")
        }
        return this.token(ast.LT, "<")
    }
    
    utils.panic("SyntaxError: unknown token '%s' line:%d column:%d  file:%s\n",c,this.line,this.column,this.parser.filepath)
    return this.token(ast.ILLEGAL,"invalid")
}

Scanner::priority(op)
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

Scanner::print()
{
    this.get_next()
    while this.curToken != ast.END {
        fmt.println(ast.getTokenString(this.curToken,this.curLex))
        this.get_next()
    }

}