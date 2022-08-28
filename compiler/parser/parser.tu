use string
use std
use ast

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
    fullname = std.pop(string.split(filepath,"/"))
    filename = string.sub(fullname,0,std.len(fullname) - 3)
    asmfile  = filename + ".s"
    if package != "main"
        asmfile  = "co_" + package + "_" + asmfile
    this.full_package = full_package
    
    scanner = new Scanner(filepath,this)
    this.import[package] = full_package
    this.import[""]  = full_package
}
Parser::parse()
{
    scanner.scan()

    while True {
        match scanner.curToken  {
            ast.FUNC : {
                f = parseFuncDef()
                this.addFunc(f.name,f)
            }
            ast.EXTERN : {
                f = parseExternDef()
                this.addFunc(f.name, f)
            }
            ast.EXTRA : parseExtra()
            ast.USE   : parseImportDef()
            ast.CLASS : parseClassDef()
            ast.MEM   : parseStructDef()
            ast.ENUM  : parseEnumDef()
            ast.END   : return null # break
            _     : parseGlobalDef()
        }
    }
}
Parser::getpkgname()
{
    return this.full_package
}
Parser::panic(args...){
    err = fmt.sprintf(args)
    this.check(false,err)
}
Parser::check(check , err)
{
    if check return  null
    this.panic("parse: found token error token:%d:%s \n"
              "msg:%s\n"
              "line:%d column:%d file:%s\n",
              scanner.curToken,getTokenString(scanner.curToken),
              err,
              scanner.line,scanner.column,filepath)
    os.exit(-1)
}
Parser::expect(tok<i32>,str<i32>){
    if this.scanner.curToken == tok {
        return  True
    }
    msg = EMPTY_STR
    if str != null {
        msg = str
    }
    err = fmt.sprintf("parse: found token error token:%s \n msg:%s\n line:%d column:%d file:%s\n",
            ast.getTokenString(scanner.curToken),
            msg,this.scanner.line,scanner.column,this.filepath
    )
    os.panic(err)
}

Parser::isunary(){
    match scanner.curToken {
        std.SUB | ast.SUB | ast.LOGNOT | ast.BITNOT : {
            return True
        }
        _ : return False
    }
}
Parser::isprimary(){
    match scanner.curToken {
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
    match scanner.curToken {
        ast.ASSIGN | ast.ADD_ASSIGN | ast.SUB_ASSIGN | ast.MUL_ASSIGN |
        ast.DIV_ASSIGN | ast.MOD_ASSIGN | ast.BITAND_ASSIGN | ast.BITOR_ASSIGN | 
        ast.SHL_ASSIGN | ast.SHR_ASSIGN : {
            return True
        }
        _ : return False
    }
}
Parser::isbinary(){
    match scanner.curToken {
        ast.SHL | ast.SHR | ast.BITOR | ast.BITAND | ast.BITNOT | ast.LOGOR |  
        ast.LOGAND | ast.LOGNOT | ast.EQ | ast.NE | ast.GT | ast.GE | ast.LT |
        ast.LE | ast.ADD | ast.SUB | ast.MOD | ast.MUL | ast.DIV : {
            return True
        }
        _ : return False
    }
}
