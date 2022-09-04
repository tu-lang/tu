use parser
use ast
use utils

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
    this.fs = new std.File(filepath)
    this.pos = 0

    if !fs.IsOpen() {
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
    if pos >= std.len(this.buffer) {
        return EOF
    }
    this.column += 1
    ret = this.buffer[pos]
    this.pos += 1
    return ret
}
Scanner::peek() {
    if pos >= std.len(buffer) {
        return EOF
    }
    this.column += 1
	return this.buffer[pos]
}
Scanner::emptyline(){
    tx = this.transaction()
    c = this.next()
    while c != EOF && c != '\n' && c !='#' && c !='/'  {
        if c != ' ' {
            rollback(t)
            return false
        }
        c = this.next()
    }
    rollback(t)
    return true
}

Scanner::consumeLine()
{
    c = this.next()
    ret
    while c != ast.EOF && c != '\n' ){
        ret += c
        c = this.next()
    }
    return ret
}

Scanner::parseNumber(first)
{
    lexeme = first
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
    

    while ( (cn >= '0' && cn <= '9') || (!isDouble && cn == '.') ) {
        if c == '.'
            isDouble = true
        c = this.next()
        cn = this.peek()
        lexeme += c
    }
    if isDouble return this.token(ast.INT,lexeme)
    else        return this.token(ast.FLOAT,lexeme)
}
Scanner::parseKeyword(c)
{
    lexeme = c
    cn

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
        return this.token(ast.keywords[lexeme],lexeme)
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
    p.line = line
    p.column = column
}

Scanner::get_next() {
    c = this.next()
    if c == EOF
        return this.token(ast.END,"")
    blank:
    if c == ' ' || c == '\n' || c == '\r' || c == '\t'{
        while(c == ' ' || c == '\n' ||c == '\r' || c == '\t'){
            if c == '\n'{
                line += 1
                column = 0
            }
            c = this.next()
        }
        if c == EOF
            return this.token(ast.END,"")
    }
    //TODO: support /*
    if c == '#' || ( c == '/' && this.peek() == '/') {
        cn = this.peek()
        if c == '/'{
            c = this.next()
            cn = this.peek()
        }
        if cn == ':' {
            
            c = this.next()
            return this.token(ast.EXTRA,"")
        }
        comment:
        while(c != '\n' && c != EOF){
            c = this.next()
        }
        
        while(c == '\n'){
            line += 1
            column = 0
            c = this.next()
        }
        if c == '#' || (c == '/' && this.peek( == '/'))
            goto comment
        if c == EOF
            return this.token(ast.END,"")
        goto blank
    }
    if c >= '0' && c <= '9'{
        return parseNumber(c)
    }
    if  c >= 'a' && c <= 'z' || c >= 'A' && c <= 'Z' || c == '_' {
        return parseKeyword(c)
    }
    if c == '.'{
        lexeme
        lexeme += c
        return this.token(ast.DOT,lexeme)
    }
    if c == ':'{
        lexeme
        lexeme += c
        return this.token(ast.COLON,lexeme)
    }
    if c == ';' {
        lexeme
        lexeme += c
        return this.token(ast.SEMI ast.COLON,lexeme)
    }
    
    if c == '\'' {
        lexeme
        lexeme += this.next()
        if (this.peek() != '\'') {
            p = parser
            utils.panic("SyntaxError: a character lit should surround with single-quote %s\n",p.filepath)
        }
        c = this.next()
        return this.token(ast.CHAR, lexeme)
    }
    
    if c == '\"'{
        lexeme
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
    if c == '-'{
        cn = this.peek()
        if cn == '='{
            c = this.next()
            return this.token(ast.SUB_ASSIGN,"-=")
        }else if cn >= '0' && cn <= '9'{
            
            return parseNumber('-')
        }
        return this.token(ast.SUB,"-")
    }
    if c == '*'
        return parseMulOrDelref(c)

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
    
    p = parser
    utils.panic("SyntaxError: unknown token '%c' line:%d column:%d  file:%s\n",c,line,column,p.filepath)
    return this.token(ast.ILLEGAL,"invalid")
}

Scanner::priority(op)
{
    match op {
        ast.LOGOR :  return 1
        ast.LOGAND:  return 2
        ast.EQ|ast.NE|ast.GT|ast.GE|ast.LT|ast.LE :        
                     return 3
        ast.ADD|ast.SUB|ast.BITOR :
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