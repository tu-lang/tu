use asmer.ast
use asmer.utils
use std
use string
use os

EOF<i32> = -1
Null<i32> = 0

mem Scanner {
    i8*    buffer
    i32    buffersize
    i32    curtoken

    i32    line,column
	i32    pos
    string.String* curlex
    string.String* filepath
}

labels = {
    ".global" : ast.KW_GLOBAL, ".globl"  : ast.KW_GLOBAL, ".text"   : ast.KW_TEXT,
    ".data"   : ast.KW_DATA,   ".string": ast.KW_STRING, ".size"   : ast.KW_SIZE,
    ".quad": ast.KW_QUAD,    ".long": ast.KW_LONG,      ".value": ast.KW_VALUE,   ".byte": ast.KW_BYTE,
    ".zero": ast.KW_ZERO,

    "push" : ast.KW_PUSH,      "pop" : ast.KW_POP,       "int" : ast.KW_INT,      
    "movb": ast.KW_MOVB,       "movw": ast.KW_MOVW,     "movl": ast.KW_MOVL,        "movq": ast.KW_MOVQ,       "movabsq": ast.KW_MOVQ,
    "mov" : ast.KW_MOV,        "movsxd": ast.KW_MOVSXD,   "movzb": ast.KW_MOVZB,    "movzbl": ast.KW_MOVZBL,   "movsbl": ast.KW_MOVSBL,
    "movzwl": ast.KW_MOVZWL,    "movswl": ast.KW_MOVSWL,   "movzx": ast.KW_MOVZX,      "shl": ast.KW_SHL,         "shr": ast.KW_SHR,        
    "sar": ast.KW_SAR,         "sub" : ast.KW_SUB,        
    "add" : ast.KW_ADD,        "addq" : ast.KW_ADD,      "xadd": ast.KW_XADD,
    "and" : ast.KW_AND,        "imul" : ast.KW_MUL,      "jg" : ast.KW_JG,        "jl": ast.KW_JL,
    "jle" : ast.KW_JLE,        "jna": ast.KW_JNA,        "dec" : ast.KW_DEC,

    "callq": ast.KW_CALL,        "call": ast.KW_CALL,       "sete": ast.KW_SETE,       "setl": ast.KW_SETL,      "setle": ast.KW_SETLE,    
    "setge": ast.KW_SETGE,       "setbe": ast.KW_SETBE,     "setg": ast.KW_SETG,       "setne": ast.KW_SETNE,    "setb": ast.KW_SETB,
    "setz": ast.KW_SETZ,         "setnz": ast.KW_SETNZ,     "seta": ast.KW_SETA,      "setae": ast.KW_SETAE,
    "jmp" : ast.KW_JMP,          "not": ast.KW_NOT,         "lea" : ast.KW_LEA,        
    "cmp" : ast.KW_CMP,          "cmpxchgq": ast.KW_CMPXCHG,"cmpxchgl": ast.KW_CMPXCHG, "cmpxchgb": ast.KW_CMPXCHG,
    "xchg": ast.KW_XCHG,         "jbe": ast.KW_JBE,
    "je" : ast.KW_JE,            "jne": ast.KW_JNE,
    "idiv": ast.KW_IDIV,         "idivq": ast.KW_IDIV,       "div": ast.KW_DIV,        "or": ast.KW_OR,             "orl": ast.KW_OR,       
    "xor": ast.KW_XOR,           "xorl": ast.KW_XOR,
    "cvtsi2sd": ast.KW_CVTSI2SD, "cvtsi2sdq": ast.KW_CVTSI2SD,

    "ret": ast.KW_RET,          "retq": ast.KW_RET,   "cltd": ast.KW_CLTD,       "cdq": ast.KW_CDQ,       "cqo": ast.KW_CQO,    
    "lock": ast.KW_LOCK,        "leaveq": ast.KW_LEAVE,   "leave": ast.KW_LEAVE,
    "syscall": ast.KW_SYSCALL,  "rdtscp": ast.KW_RDTSCP,  "pause": ast.KW_PAUSE,

    "%al": ast.KW_AL,          "%cl": ast.KW_CL,          "%dl": ast.KW_DL,         "%bl": ast.KW_BL,
    "%ah": ast.KW_AH,          "%ch": ast.KW_CH,          "%dh": ast.KW_DH,         "%bh": ast.KW_BH,

    "%eax": ast.KW_EAX,        "%ecx": ast.KW_ECX,        "%edx": ast.KW_EDX,       "%ebx": ast.KW_EBX,
    "%esp": ast.KW_ESP,        "%ebp": ast.KW_EBP,        "%esi": ast.KW_ESI,       "%edi": ast.KW_EDI,

    "%rax": ast.KW_RAX,      "%rbx": ast.KW_RBX,      "%rcx": ast.KW_RCX,
    "%rdx": ast.KW_RDX,      "%rdi": ast.KW_RDI,     "%rsi": ast.KW_RSI,
    "%r8": ast.KW_R8,        "%r9": ast.KW_R9,       "%r10": ast.KW_R10,
    "%r11": ast.KW_R11,      "%r12": ast.KW_R12,     "%r13": ast.KW_R13,    "%r14": ast.KW_R14, "%r15": ast.KW_R15,
    "%xmm0": ast.KW_XMM0,    "%xmm1": ast.KW_XMM1,   "%xmm2": ast.KW_XMM2,  "%xmm3": ast.KW_XMM3,
    "%xmm4": ast.KW_XMM4,    "%xmm5": ast.KW_XMM5,   "%xmm6": ast.KW_XMM6,  "%xmm7": ast.KW_XMM7,
    "%xmm8": ast.KW_XMM8,    "%xmm9": ast.KW_XMM9,   "%xmm10": ast.KW_XMM10,  "%xmm11": ast.KW_XMM11,
    "%xmm12": ast.KW_XMM12,    "%xmm13": ast.KW_XMM13,   "%xmm14": ast.KW_XMM14,  "%xmm15": ast.KW_XMM15,
    "%rsp": ast.KW_RSP,      "%rbp": ast.KW_RBP,     "%rip": ast.KW_RIP,    "%fs": ast.KW_FS,
    "%ax": ast.KW_RAX,
    //debug 
    ".file": ast.KW_DEBUG_FILE,
    ".loc" : ast.KW_DEBUG_LOC
}
specs = 
{
	 "\\n" : 10,
	 "\\\\" : 92,
	 "\\t" : 9,
	 "\\\'" : 39,
	 "\\\"" : 34,
	 "\\b" : 8,
	 "\\r" : 13,
	 "\\f" : 12,
	 "\\0" : 0,
     "\\r" : 13,
     "\\v" :11,
}
func char(cn<i8>){
    return runtime.newobject(runtime.Char,cn)
}

Scanner::init(filepath)
{
    utils.debug("Scanner::init() %s".(i8),*filepath)
    this.filepath = filepath
    this.pos      = 0
    fs = new std.File(filepath)

    if !fs.IsOpen() {
        os.die("error opening file :" + filepath )
    }

    this.buffer = fs.ReadAllNative()
    if this.buffer == 0 {
        os.die("error reade file:" + filepath)
    }
    totalsize = fs.size
    this.buffersize = *totalsize
    utils.debug("Scanner::init() end %s".(i8),*filepath)
}
Scanner::next() {
    if this.pos >= this.buffersize {
        return EOF
    }
    p<i32> = this.pos
    this.pos += 1
    this.column += 1
    return this.buffer[p]
}
Scanner::peek() {
    if this.pos >= this.buffersize{
        return EOF
    }
    return this.buffer[this.pos]
}
Scanner::token(tk<i32>,lex<string.String>){
    this.curlex = lex
    this.curtoken = tk
}
Scanner::scan(){
    this._scan()
    return this.curtoken
}
// parseNumber
Scanner::parseNumber(first<i8>)
{
    lexeme<string.String> = string.emptyS()
    lexeme.putc(first)

    isDouble<i32> = false
    cn<i8> = this.peek()
    c<i8>  = first
    if (c == '0' && cn == 'x'){
        while((cn >= 'a' && cn <= 'z') || (cn >= 'A' && cn <= 'Z') || (cn >= '0' && cn <= '9')){
            c = this.next()
            lexeme.putc(c)
            cn = this.peek()
        }
        return this.token(ast.TK_NUMBER,lexeme)
    }
    while(cn >= '0' && cn <= '9'){
        if(c == '.' && this.peek() != '(')
            isDouble = true
        c = this.next()
        cn = this.peek()
        lexeme.putc(c)
    }
    if isDouble {
        return this.token(ast.TK_DOUBLE,lexeme)
    }
    return this.token(ast.TK_NUMBER,lexeme)
}
Scanner::parseString(c<i8>)
{
    lexeme<string.String> = string.emptyS()
    cn<i8> = this.peek()
    while(cn != '"'){
        c = this.next()
        if ( c == '\\'){
            ts = "\\"
            c = this.next()
            //dyn type
            ts += char(c)

            if ts != "\\0" && !specs[ts] {
                utils.errorf(
                    "SyntaxError: sepc [%s] character literal should surround with single-quote %s line:%d column:%d\n ",
                    ts, this.filepath,int(this.line),int(this.column)
                )
            }
            //dyn type
            specsv = specs[ts]
            lexeme.putc(*specsv)
        }else{
            lexeme.putc(c)
        }
        cn = this.peek()
    }
    c = this.next()
    return this.token(ast.TK_STRING,lexeme)
}
Scanner::parseKeyword(c<i8>)
{
    lexeme<string.String> = string.emptyS()
    lexeme.putc(c)

    cn<i8> = this.peek()
    while((cn >= 'a' && cn <= 'z') || (cn >= 'A' && cn <= 'Z') || cn == '.' || cn == '_' || (cn >= '0' && cn <= '9')){
        c = this.next()
        lexeme.putc(c)
        cn = this.peek()
    }
    //dyn str
    lex = lexeme.dyn()
    if std.exist(lex,labels) {
       return this.token(labels[lex],lexeme) 
    }
    return this.token(ast.KW_LABEL, lexeme)
}
Scanner::_scan() {
    c<i8> = this.next()
    if(c == EOF) return this.token(ast.TK_EOF,Null)
blank:
    if(c == ' ' || c == '\n' || c == '\r' || c == '\t'){
        while(c == ' ' || c == '\n' ||c == '\r' || c == '\t'){
            if(c == '\n'){
                this.line += 1
                this.column = 0
            }
            c = this.next()
        }
        if(c == EOF)
            return this.token(ast.TK_EOF,Null)
    }
    if(c == '#'){
comment:
        while(c != '\n' && c != EOF) {
            c = this.next()
        }
        while(c == '\n'){
            this.line += 1
            this.column = 0
            c = this.next()
        }
        if(c == '#')
            goto comment
        if(c == EOF)
            return this.token(ast.TK_EOF,Null)
        goto blank
    }
    if(c >= '0' && c <= '9') return this.parseNumber(c)
    if( c == '.' || (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_') 
        return this.parseKeyword(c)

    if(c == '\"') return this.parseString(c)
    if(c == ':')  return this.token(ast.TK_COLON   ,string.S(*":"))
    if(c == '(')  return this.token(ast.TK_LPAREN  ,string.S(*"("))
    if(c == ')')  return this.token(ast.TK_RPAREN  ,string.S(*")"))
    if(c == ',')  return this.token(ast.TK_COMMA   ,string.S(*","))
    if(c == '%')  return this.parseKeyword('%'.(i8))
    if(c == '-')  {
        cn<i8> = this.peek()
        if(cn >= '0' && cn <= '9'){
            return this.parseNumber('-'.(i8))
        }
        return this.token(ast.TK_SUB     ,string.S("-".(i8)))
    }
    if(c == '*')  return this.token(ast.TK_MUL     ,string.S("*".(i8)))
    if(c == '@')  return this.token(ast.TK_AT      ,string.S("@".(i8)))
    if(c == '$')  return this.token(ast.TK_IMME    ,string.S("$".(i8)))

    utils.errorf(
        "SynxaxError: unknown token %c line:%d column:%d file:%s\n",
        char(c),int(this.line),int(this.column),this.filepath
    )
    return this.token(ast.INVALID,string.S("invalid".(i8)))
}
