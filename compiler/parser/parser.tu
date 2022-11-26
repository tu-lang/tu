use string
use std
use ast
use parser.scanner
use utils

//optimize: avoid alloc so many object like this
True  = true
False = false
EMPTY_STR = ""

I8  = int(ast.I8)  U8  = int(ast.U8) 
I16 = int(ast.I16) U16 = int(ast.U16) 
I32 = int(ast.I32) U32 = int(ast.U32)
I64 = int(ast.I64) U64 = int(ast.U64)
typesize = {
    I8 : 1 , I16 : 2 , I32 : 4 , I64 : 8,
    U8 : 1 , U16 : 2 , U32 : 4 , U64 : 8
}
EOF = -1 //FXIME: EOF
count = 1 

class Parser {
    gvars = {} # map{string:VarExpr} global vars

    //stor all global function
    funcs = {}         # map{string:Function}
    extern_funcs = {}  # map[string]Function

    strs = []          # [gen.StringExpr]  all static string
    
    links = []         # [string] ld link args

    line column fileno

    pkg         = pkg   # Package*
    currentFunc = null
    full_package # package name
    package     = package      
    filename   
    asmfile
    filepath    = filepath

    //currently scanner
    scanner #Scanner*
    import  = {} # map{string : string }    full package path => user use path
}

Parser::init(filepath,pkg,package,full_package) {
    utils.debugf(
        "parser.Parser::init() filename:%s package:%s full_package:%s"
        filepath,package,full_package
    )
    fullname = std.pop(string.split(filepath,"/"))
    this.filename = string.sub(fullname,0,std.len(fullname) - 3)
    this.asmfile  = this.filename + ".s"
    if package != "main"
        this.asmfile  = "co_" + package + "_" + this.asmfile

    this.full_package = full_package
    
    this.scanner = new scanner.Scanner(filepath,this)
    this.import[package] = full_package
    this.import[""]  = full_package
    this.filenameid = ".L.filename." +  ast.incr_labelid()

}
Parser::parse()
{
    this.scanner.scan()
    utils.debug("parser.Parser::parse() tk:%s",this.scanner.curLex)

    while True {
        match this.scanner.curToken  {
            ast.FUNC : {
                f = this.parseFuncDef(false,false)
                this.addFunc(f.name,f)
            }
            ast.EXTERN : {
                f = this.parseExternDef()
                this.addFunc(f.name, f)
            }
            ast.EXTRA : this.parseExtra()
            ast.USE   : this.parseImportDef()
            ast.CLASS : this.parseClassDef()
            ast.MEM   : this.parseStructDef()
            ast.ENUM  : this.parseEnumDef()
            ast.END   : return null 
            _     : this.parseGlobalDef()
        }
    }
}
Parser::getpkgname()
{
    return this.full_package
}
Parser::panic(args...){
    fmt.println("Parser::panic:")
    err = fmt.sprintf(args)
    this.check(false,err)
}
Parser::check(check<runtime.Value> , err<i8*>)
{
    //static
    if check == 1 return  null
    if check == 0 goto check_panic 
    //dyn
    c = check
    if c return null
check_panic:
    msg = err
    if err == null msg = ""
    //FIXME: 这里继续调用this.panic() 导致循环调用栈处理异常
    os.dief (
        "parse: found token error token: %s \n" +
        "msg:%s \n" + 
        "line:%d column:%d file:%s\n",
        this.scanner.curLex,msg,
        this.scanner.line,this.scanner.column,this.filepath
    )
}
Parser::expect(tok<i32>,str<i32>){
    if this.scanner.curToken == tok {
        return  True
    }
    msg = EMPTY_STR
    if str != null {
        msg = str
    }
    err = fmt.sprintf(
        "parse: found token error token:%s(%s) expect:%s\n msg:%s\n line:%d column:%d file:%s\n",
        ast.getTokenString(this.scanner.curToken),
        this.scanner.curLex,
        ast.getTokenString(tok),
        msg,this.scanner.line,this.scanner.column,this.filepath
    )
    os.panic(err)
}
Parser::next_expect(tk,err<i8*>){
    this.scanner.scan()
    return this.expect(tk,err)
}

Parser::isunary(){
    match this.scanner.curToken {
        ast.SUB | ast.SUB | ast.LOGNOT | ast.BITNOT : {
            return True
        }
        _ : return False
    }
}
Parser::isprimary(){
    match this.scanner.curToken {
        ast.FLOAT  | ast.INT      | ast.CHAR     | ast.STRING | ast.VAR    | 
        ast.FUNC   | ast.LPAREN   | ast.LBRACKET | ast.LBRACE | ast.RBRACE | 
        ast.BOOL   | ast.EMPTY    | ast.NEW      | ast.DOT    | ast.DELREF |
        ast.BITAND | ast.BUILTIN : {
            return True
        }
        _ : return False
    }
}
Parser::ischain(){
    match this.scanner.curToken {
        ast.DOT | ast.LPAREN | ast.LBRACKET : {
            return True
        }
        _ : return False
    }
}
Parser::isassign(){
    match this.scanner.curToken {
        ast.ASSIGN | ast.ADD_ASSIGN | ast.SUB_ASSIGN | ast.MUL_ASSIGN |
        ast.DIV_ASSIGN | ast.BITXOR_ASSIGN | ast.MOD_ASSIGN | ast.BITAND_ASSIGN | ast.BITOR_ASSIGN | 
        ast.SHL_ASSIGN | ast.SHR_ASSIGN : {
            return True
        }
        _ : return False
    }
}
Parser::isbinary(){
    match this.scanner.curToken {
        ast.SHL | ast.SHR | ast.BITOR | ast.BITXOR | ast.BITAND | ast.BITNOT | ast.LOGOR |  
        ast.LOGAND | ast.LOGNOT | ast.EQ | ast.NE | ast.GT | ast.GE | ast.LT |
        ast.LE | ast.ADD | ast.SUB | ast.MOD | ast.MUL | ast.DIV : {
            return True
        }
        _ : return False
    }
}
Parser::isbase(){
    match this.scanner.curToken {
        ast.I8 | ast.U8 | ast.I16 | ast.U16 |
        ast.I32| ast.U32| ast.I64 | ast.U64 :
            return true
    }
    return false
}