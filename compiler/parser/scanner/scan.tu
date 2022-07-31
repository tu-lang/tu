use parser
use ast

class Scanner{
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
    txpos 
    txtk
    txlex
    func init(pos,tk,lex){
        this.txpos = pos
        this.txtk = tk
        this.txlex = lex
    }
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
    c = next()
    while c != EOF && c != '\n' && c !='#' && c !='/'  {
        if c != ' ' {
            rollback(t)
            return false
        }
        c = next()
    }
    rollback(t)
    return true
}
/**
 * consumeline 
 */
Scanner::consumeLine()
{
    c = next()
    ret
    while c != EOF && c != '\n' ){
        ret += c
        c = next()
    }
    return ret
}

Scanner::parseNumber(first)
{
    lexeme = first
    isDouble = false
    cn = peek()
    c  = first
    
    if (c == '0' && cn == 'x'){
        while (cn >= 'a' && cn <= 'z') || (cn >= 'A' && cn <= 'Z') || (cn >= '0' && cn <= '9'){
            c = next()
            lexeme += c
            cn = peek()
        }
        return token(ast.INT,lexeme)
    }
    

    while (cn >= '0' && cn <= '9') || (!isDouble && cn == '.') {
        if c == '.'
            isDouble = true
        c = next()
        cn = peek()
        lexeme += c
    }
    if isDouble return token(ast.INT,lexeme)
    else        return token(ast.FLOAT,lexeme)
}
Scanner::parseKeyword(c)
{
    lexeme = c
    cn

    cn = peek()
    while((cn >= 'a' && cn <= 'z') || (cn >= 'A' && cn <= 'Z') || cn == '_' || (cn >= '0' && cn <= '9')){

        c = next()
        lexeme += c
        cn = peek()
    }
    
    if lexeme == "new" && cn == '('{
        return token(ast.VAR,lexeme)
    }
    if std.exist(keywords,lexeme){
        return token(ast.keywords[lexeme],lexeme)
    } 
    if std.exist(keywords,lexeme) && peek() == '(' {
        return token(ast.BUILTIN,lexeme)
    }

    return token(ast.VAR,lexeme)
}

Scanner::parseMulOrDelref(c)
{
    cn = peek()
    
    if cn == '='  {
        c = next()
        return token(ast.MUL_ASSIGN, "*=")
    }
    
    if (cn >= 'a' && cn <= 'z' || (cn >= 'A' && cn <= 'Z')){
        return token(ast.DELREF, "*")
    }
    
    if cn == '\"'                  
        return token(ast.DELREF, "*")
    return token(ast.MUL, "*")
}

Scanner::token(ast.tk,lex){
    this.curLex = lex
    this.curToken = tk
}
Scanner::scan(){
    prevLex   = curLex
    prevToken = curToken

    //token
    get_next()

    p = this.parser
    p.line = line
    p.column = column
}

Scanner::get_next() {
    c = next()
    if c == EOF
        return token(ast.END,"")
    blank:
    if c == ' ' || c == '\n' || c == '\r' || c == '\t'{
        while(c == ' ' || c == '\n' ||c == '\r' || c == '\t'){
            if c == '\n'{
                line++
                column = 0
            }
            c = next()
        }
        if c == EOF
            return token(ast.END,"")
    }
    //TODO: support /*
    if c == '#' || ( c == '/' && peek() == '/') {
        cn = peek()
        if c == '/'{
            c = next()
            cn = peek()
        }
        if cn == ':' {
            
            c = next()
            return token(ast.EXTRA,"")
        }
        comment:
        while(c != '\n' && c != EOF)
            c = next()
        
        while(c == '\n'){
            line++
            column = 0
            c = next()
        }
        if c == '#' || (c == '/' && peek( == '/'))
            goto comment
        if c == EOF
            return token(ast.END,"")
        goto blank
    }
    if c >= '0' && c <= '9'{
        return parseNumber(c)
    }
    if  c >= 'a' && c <= 'z' || c >= 'A' && c <= 'Z' || c == '_'){
        return parseKeyword(c)
    }
    if c == '.'{
        lexeme
        lexeme += c
        return token(ast.DOT,lexeme)
    }
    if c == ':'{
        lexeme
        lexeme += c
        return token(ast.COLON,lexeme)
    }
    if c == ';'{
        lexeme
        lexeme += c
        return token(ast.SEMI ast.COLON,lexeme)
    }
    
    if (c == '\'') {
        lexeme
        lexeme += next()
        if (peek() != '\'') {
            p = parser
            parse_err("SyntaxError: a character literal should surround with single-quote %s\n",p.filepath)
        }
        c = next()
        return token(ast.CHAR, lexeme)
    }
    
    if c == '\"'{
        lexeme
        cn = peek()
        while(cn != '"'){
            c = next()
            lexeme += c
            cn = peek()
        }
        c = next()
        return token(ast.STRING,lexeme)
    }
    
    if c == '[' return token(ast.LBRACKET,"[")
    if c == ']' return token(ast.RBRACKET,"]")
    if c == '{' return token(ast.LBRACE  ,"{")
    if c == '}' return token(ast.RBRACE  ,"}")
    if c == '(' return token(ast.LPAREN  ,"(")
    if c == '') return token(ast.RPAREN  ,")")
    if c == ',' return token(ast.COMMA   ,",")

    if c == '+'{
        cn = peek()
        if cn == '='{
            c = next()
            return token(ast.ADD_ASSIGN,"+=")
        }
        return token(ast.ADD        ,"+")
    }
    if c == '-'{
        cn = peek()
        if cn == '='{
            c = next()
            return token(ast.SUB_ASSIGN,"-=")
        }else if cn >= '0' && cn <= '9'{
            
            return parseNumber('-')
        }
        return token(ast.SUB,"-")
    }
    if c == '*'
        return parseMulOrDelref(c)

    if c == '/' {
        cn = peek()
        if (cn == '=') {
            c = next()
            return token(ast.DIV_ASSIGN, "/=")
        }
        return token(ast.DIV, "/")
    }
    if c == '%' {
        cn = peek()
        if (cn == '=') {
            c = next()
            return token(ast.MOD_ASSIGN, "%=")
        }
        return token(ast.MOD, "%")
    }
    
    if (c == '~') return token(ast.BITNOT,"~")
    if (c == '=') {
        if (peek() == '=') {
            c = next()
            return token(ast.EQ, "==")
        }
        return token(ast.ASSIGN, "=")
    }
    if (c == '!') {
        if (peek() == '=') {
            c = next()
            return token(ast.NE, "!=")
        }
        return token(ast.LOGNOT, "!")
    }
    if (c == '|') {
        if (peek() == '|') {
            c = next()
            return token(ast.LOGOR, "||")
        }
        if (peek() == '=') {
            c = next()
            return token(ast.BITOR_ASSIGN, "|=")
        }
        return token(ast.BITOR, "|")
    }
    if (c == '&') {
        if (peek() == '&') {
            c = next()
            return token(ast.LOGAND, "&&")
        }
        if (peek() == '=') {
            c = next()
            return token(ast.BITAND_ASSIGN, "&=")
        }
        return token(ast.BITAND, "&")
    }
    if (c == '>') {
        
        if (peek() == '=') {
            c = next()
            return token(ast.GE, ">=")
        }
        
        if (peek() == '>') {
            c = next()
            
            if (peek() == '=') {
                c = next()
                return token(ast.SHR_ASSIGN, ">>=")
            }
            return token(ast.SHR, ">>")
        }

        return token(ast.GT, ">")
    }
    if (c == '<') {
        if (peek() == '=') {
            c = next()
            return token(ast.LE, "<=")
        }
        if (peek() == '<') {
            c = next()
            
            if (peek() == '=') {
                c = next()
                return token(ast.SHL_ASSIGN, "<<=")
            }
            return token(ast.SHL, "<<")
        }
        return token(ast.LT, "<")
    }
    
    p = parser
    parse_err("SyntaxError: unknown token '%c' line:%d column:%d  file:%s\n",c,line,column,p.filepath)
    return token(ast.ILLEGAL,"invalid")
}

Scanner::precedence(Token op)
{
    match op {
        LOGOR:  return 1
        LOGAND: return 2
        EQ  | NE  | GT | GE | LT | LE:        return 3
        ADD | SUB | BITOR:                    return 4
        ast.MUL | MOD | DIV | BITAND | SHL | SHR: return 5
        _ :     return 0
    }

}

Scanner::print()
{
    get_next()
    while curToken != END {
        fmt.println(getTokenString(curToken,curLex))
        get_next()
    }

}