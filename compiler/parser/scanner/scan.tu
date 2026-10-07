use compiler.ast
use compiler.utils
use std
use string
use runtime
use os
use fmt

// Tu lexer. Byte-level work runs in unsafe blocks over a static string.Cursor
// (buffer, length, pos, line, column); class Scanner is the dynamic facade the
// parser drives one token at a time. curToken/prevToken hold ast token ids,
// curLex/prevLex hold dyn strings.

// Builds the keyword table once (ast token globals are ready at package init).
func init(){
    initKeywords()
}

// Per-file lexer state.
class Scanner {
    cur         // string.Cursor (static mem) over the file body
    filepath
    parser      // owning Parser; line/column are mirrored onto it after each scan
    curToken
    curLex
    prevToken
    prevLex
    line
    column
}

// Rollback snapshot: cursor offset plus the current token (line/column keep running).
class Tx {
    txpos
    txtk
    txlex
    func init(pos, tk, lex){
        this.txpos = pos
        this.txtk = tk
        this.txlex = lex
    }
}

// Reads filepath into a static cursor; dies when the file cannot be read.
// A null filepath leaves the cursor unset for fromText.
Scanner::init(filepath, parser){
    utils.debugf("parser.scanner.Scanner::init() filepath:%s",filepath)
    this.filepath = filepath
    this.parser = parser
    this.curToken = ast.ILLEGAL
    this.curLex = ""
    this.prevToken = ast.ILLEGAL
    this.prevLex = ""
    this.line = 1
    this.column = 0
    if filepath == null return
    ok = false
    unsafe {
        err<i32>, bits<u64> = string.cursor_open(filepath)
        if err == 0 {
            c<string.Cursor> = bits.(string.Cursor)
            this.cur = c
            ok = true
        }
    }
    if !ok {
        os.die("error opening file :" + filepath)
    }
}

// Lexes an in-memory source; filepath is only used in diagnostics.
func fromText(filepath, text, parser){
    s = new Scanner(null, parser)
    s.filepath = filepath
    unsafe {
        c<string.Cursor> = string.cursor_from_string(text)
        s.cur = c
    }
    return s
}

// Rewinds to the start of the file (parse3 re-parses each file).
Scanner::reset(){
    raw = this.cur
    unsafe {
        c<string.Cursor> = raw.(string.Cursor)
        c.pos = 0
        c.line = 1
        c.column = 0
    }
    this.line = 1
    this.column = 0
}

Scanner::transaction(){
    raw = this.cur
    pos = 0
    unsafe {
        c<string.Cursor> = raw.(string.Cursor)
        pos = int(c.pos)
    }
    return new Tx(pos, this.curToken, this.curLex)
}

Scanner::rollback(x){
    raw = this.cur
    pos = x.txpos
    unsafe {
        c<string.Cursor> = raw.(string.Cursor)
        pv<runtime.Value> = pos
        c.pos = pv.data
    }
    this.curToken = x.txtk
    this.curLex = x.txlex
}

// Byte at the cursor without consuming it: a Char, or Int -1 at end of input.
Scanner::peek(){
    raw = this.cur
    unsafe {
        c<string.Cursor> = raw.(string.Cursor)
        return string.cursor_char_value(c.peek())
    }
}

// Sets the current token and returns its id.
Scanner::token(tk, lex){
    this.curLex = lex
    this.curToken = tk
    return tk
}

// Consumes a balanced { ... } block (curToken must be '{') and scans past it.
Scanner::skipblock(){
    if this.curToken != ast.LBRACE {
        os.dief("[error] skipblock not {")
    }
    block = 1
    while block != 0 {
        tk = this.scan()
        if tk == ast.RBRACE block -= 1
        if tk == ast.LBRACE block += 1
        // An unmatched '{' would otherwise keep yielding END forever.
        if tk == ast.END {
            os.dief("[error] unexpected EOF while skipping block, unmatched '{' file:%s line:%d column:%d",this.filepath,this.line,this.column)
        }
    }
    this.scan()
}

// True when the rest of the line is blank or starts a comment (cursor unchanged).
Scanner::emptyline(){
    raw = this.cur
    ret = true
    unsafe {
        c<string.Cursor> = raw.(string.Cursor)
        pos<i32> = c.pos
        col<i32> = c.column
        ch<i32> = c.next()
        while ch != string.CURSOR_EOF && ch != '\n' && ch != '#' && ch != '/' {
            if ch != ' ' && ch != '\t' {
                ret = false
                break
            }
            ch = c.next()
        }
        c.pos = pos
        c.column = col
    }
    return ret
}

// Returns the remainder of the line and consumes its newline.
Scanner::consumeLine(){
    raw = this.cur
    unsafe {
        c<string.Cursor> = raw.(string.Cursor)
        ret<string.String> = string.emptyS()
        ch<i32> = c.next()
        while ch != string.CURSOR_EOF && ch != '\n' {
            ret.putc(ch)
            ch = c.next()
        }
        return ret.dyn()
    }
}

// Decimal / float / hex literal starting with first (already consumed).
Scanner::parseNumber(first){
    raw = this.cur
    tk = ast.INT
    lex = ""
    unsafe {
        c<string.Cursor> = raw.(string.Cursor)
        fv<runtime.Value> = first
        ch<i32> = fv.data
        lexeme<string.String> = string.emptyS()
        lexeme.putc(ch)
        isDouble<i32> = 0
        cn<i32> = c.peek()

        if ch == '0' && cn == 'x' {
            while ((cn >= 'a' && cn <= 'z') || (cn >= 'A' && cn <= 'Z') || (cn >= '0' && cn <= '9')) {
                ch = c.next()
                lexeme.putc(ch)
                cn = c.peek()
            }
        }else{
            while ((cn >= '0' && cn <= '9') || (isDouble == 0 && cn == '.')) {
                cn = c.peek()
                if ch == '.' && cn != '('
                    isDouble = 1
                ch = c.next()
                cn = c.peek()
                // "1.(i8)" is a cast on an int literal: give the '.' back.
                if ch == '.' && cn == '(' {
                    c.column -= 1
                    c.pos -= 1
                    break
                }
                lexeme.putc(ch)
            }
            if isDouble == 1 tk = ast.FLOAT
        }
        lex = lexeme.dyn()
    }
    return this.token(tk, lex)
}

// Identifier, keyword, or builtin call name starting with first (already consumed).
Scanner::parseKeyword(first){
    raw = this.cur
    lex = ""
    isnew = false
    callnext = false
    unsafe {
        c<string.Cursor> = raw.(string.Cursor)
        fv<runtime.Value> = first
        ch<i32> = fv.data
        lexeme<string.String> = string.emptyS()
        lexeme.putc(ch)
        cn<i32> = c.peek()
        while ((cn >= 'a' && cn <= 'z') || (cn >= 'A' && cn <= 'Z') || cn == '_' || (cn >= '0' && cn <= '9')) {
            ch = c.next()
            lexeme.putc(ch)
            cn = c.peek()
        }
        if cn == '(' callnext = true
        if lexeme.cmpstr(*"new") == string.Equal && cn == '(' isnew = true
        lex = lexeme.dyn()
    }
    if isnew return this.token(ast.VAR, lex)
    tk = keywords[lex]
    if tk != null return this.token(tk, lex)
    if callnext && builtins[lex] != null return this.token(ast.BUILTIN, lex)
    return this.token(ast.VAR, lex)
}

// Character literal after the opening quote; lexeme is the signed byte value in decimal.
Scanner::parseChar(){
    raw = this.cur
    lit = 0
    esc = null
    unsafe {
        c<string.Cursor> = raw.(string.Cursor)
        l<i32> = c.next()
        if l == '\\' {
            esc = "\\" + string.cursor_char_value(c.next())
        }else{
            lit = int(l)
        }
    }
    if esc != null {
        if esc == "\\0" {
            lit = 0
        }else if !utils.has(esc, specs) {
            utils.panic(
                "SyntaxError: scanner sepc [%s] character literal should surround with single-quote file:%s line:%d",
                esc, this.filepath, this.line
            )
        }else{
            lit = specs[esc]
        }
    }
    closed = false
    unsafe {
        c<string.Cursor> = raw.(string.Cursor)
        if c.peek() == '\'' {
            c.next()
            closed = true
        }
    }
    if !closed {
        utils.panic("SyntaxError: a character lit should surround with single-quote c:%c file:%s\n",this.peek(),this.filepath)
    }
    // Char literals are signed i8.
    if lit > 127 lit -= 256
    return this.token(ast.CHAR, string.tostring(lit))
}

// String literal body after the opening quote; escapes are kept verbatim.
Scanner::parseString(){
    raw = this.cur
    lex = ""
    unsafe {
        c<string.Cursor> = raw.(string.Cursor)
        lexeme<string.String> = string.emptyS()
        cn<i32> = c.peek()
        while cn != '"' {
            ch<i32> = c.next()
            if ch == string.CURSOR_EOF {
                break
            }
            if ch == '\\' {
                lexeme.putc(ch)
                ch = c.next()
            }
            lexeme.putc(ch)
            cn = c.peek()
        }
        c.next()
        lex = lexeme.dyn()
    }
    return this.token(ast.STRING, lex)
}

// Advances to the next token and mirrors line/column onto the parser.
Scanner::scan(){
    this.prevLex   = this.curLex
    this.prevToken = this.curToken
    this.get_next()
    raw = this.cur
    unsafe {
        c<string.Cursor> = raw.(string.Cursor)
        this.line = int(c.line)
        this.column = int(c.column)
    }
    p = this.parser
    if p != null {
        p.line = this.line
        p.column = this.column
    }
    return this.curToken
}

// Skips blanks and comments, then lexes one token (same algorithm as the former
// ScannerStatic::get_next). Literals and identifiers are finished by the parse*
// helpers; operators are produced here.
Scanner::get_next(){
    raw = this.cur
    unsafe {
        c<string.Cursor> = raw.(string.Cursor)
        ch<i32> = c.next()
        cn<i32> = 0
        p<i32> = 0
        if ch == string.CURSOR_EOF
            return this.token(ast.END, "")
blank:
        if ch == ' ' || ch == '\n' || ch == '\r' || ch == '\t' {
            while ch == ' ' || ch == '\n' || ch == '\r' || ch == '\t' {
                if ch == '\n' {
                    c.line += 1
                    c.column = 0
                }
                ch = c.next()
            }
            if ch == string.CURSOR_EOF
                return this.token(ast.END, "")
        }
        p = c.peek()
        if ch == '#' || (ch == '/' && p == '/') {
comment:
            cn = c.peek()
            if ch == '/' {
                ch = c.next()
                cn = c.peek()
            }
            // "#:" / "//:" starts a directive line.
            if cn == ':' {
                c.next()
                return this.token(ast.EXTRA, "")
            }
            while ch != '\n' && ch != string.CURSOR_EOF {
                ch = c.next()
            }
            while ch == '\n' {
                c.line += 1
                c.column = 0
                ch = c.next()
            }
            p = c.peek()
            if ch == '#' || (ch == '/' && p == '/')
                goto comment
            if ch == string.CURSOR_EOF
                return this.token(ast.END, "")
            goto blank
        }
        if ch >= '0' && ch <= '9'
            return this.parseNumber(int(ch))
        if ((ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || ch == '_')
            return this.parseKeyword(int(ch))

        if ch == '.' return this.token(ast.DOT, ".")
        if ch == ':' return this.token(ast.COLON, ":")
        if ch == ';' return this.token(ast.SEMICOLON, ";")
        if ch == '\'' return this.parseChar()
        if ch == '"' return this.parseString()

        if ch == '[' return this.token(ast.LBRACKET, "[")
        if ch == ']' return this.token(ast.RBRACKET, "]")
        if ch == '{' return this.token(ast.LBRACE, "{")
        if ch == '}' return this.token(ast.RBRACE, "}")
        if ch == '(' return this.token(ast.LPAREN, "(")
        if ch == ')' return this.token(ast.RPAREN, ")")
        if ch == ',' return this.token(ast.COMMA, ",")

        cn = c.peek()
        if ch == '+' {
            if cn == '=' {
                c.next()
                return this.token(ast.ADD_ASSIGN, "+=")
            }
            return this.token(ast.ADD, "+")
        }
        if ch == '^' {
            if cn == '=' {
                c.next()
                return this.token(ast.BITXOR_ASSIGN, "^=")
            }
            return this.token(ast.BITXOR, "^")
        }
        if ch == '-' {
            if cn == '=' {
                c.next()
                return this.token(ast.SUB_ASSIGN, "-=")
            }else if cn >= '0' && cn <= '9' {
                return this.parseNumber(int(ch))
            }
            return this.token(ast.SUB, "-")
        }
        if ch == '*' {
            if cn == '=' {
                c.next()
                return this.token(ast.MUL_ASSIGN, "*=")
            }
            // Deref: "*name" or *"...".
            if ((cn >= 'a' && cn <= 'z') || (cn >= 'A' && cn <= 'Z') || cn == '_' || cn == '"')
                return this.token(ast.DELREF, "*")
            return this.token(ast.MUL, "*")
        }
        if ch == '/' {
            if cn == '=' {
                c.next()
                return this.token(ast.DIV_ASSIGN, "/=")
            }
            return this.token(ast.DIV, "/")
        }
        if ch == '%' {
            if cn == '=' {
                c.next()
                return this.token(ast.MOD_ASSIGN, "%=")
            }
            return this.token(ast.MOD, "%")
        }
        if ch == '~' return this.token(ast.BITNOT, "~")
        if ch == '=' {
            if cn == '=' {
                c.next()
                return this.token(ast.EQ, "==")
            }
            return this.token(ast.ASSIGN, "=")
        }
        if ch == '!' {
            if cn == '=' {
                c.next()
                return this.token(ast.NE, "!=")
            }
            return this.token(ast.LOGNOT, "!")
        }
        if ch == '|' {
            if cn == '|' {
                c.next()
                return this.token(ast.LOGOR, "||")
            }
            if cn == '=' {
                c.next()
                return this.token(ast.BITOR_ASSIGN, "|=")
            }
            return this.token(ast.BITOR, "|")
        }
        if ch == '&' {
            if cn == '&' {
                c.next()
                return this.token(ast.LOGAND, "&&")
            }
            if cn == '=' {
                c.next()
                return this.token(ast.BITAND_ASSIGN, "&=")
            }
            return this.token(ast.BITAND, "&")
        }
        if ch == '>' {
            if cn == '=' {
                c.next()
                return this.token(ast.GE, ">=")
            }
            if cn == '>' {
                c.next()
                if c.peek() == '=' {
                    c.next()
                    return this.token(ast.SHR_ASSIGN, ">>=")
                }
                return this.token(ast.SHR, ">>")
            }
            return this.token(ast.GT, ">")
        }
        if ch == '<' {
            if cn == '=' {
                c.next()
                return this.token(ast.LE, "<=")
            }
            if cn == '<' {
                c.next()
                if c.peek() == '=' {
                    c.next()
                    return this.token(ast.SHL_ASSIGN, "<<=")
                }
                return this.token(ast.SHL, "<<")
            }
            return this.token(ast.LT, "<")
        }
        utils.panic(
            "SyntaxError: unknown token '%d' line:%d column:%d  file:%s\n",
            int(ch), int(c.line), int(c.column), this.filepath
        )
    }
    return this.token(ast.ILLEGAL, "invalid")
}

// Binary operator precedence (0 = not a binary operator).
Scanner::priority(op){
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

// Debug dump of every remaining token.
Scanner::print(){
    this.get_next()
    while this.curToken != ast.END {
        fmt.println(ast.getTokenString(this.curToken))
        this.get_next()
    }
}
