use string
use std
use ast



typesize

I8 I16 I32 I64
U8 U16 U32 U64
EOF //FXIME: EOF

count # count = 1
func init(){
	EOF = -1
    ast.I8 = int(ast.I8) ast.I16 = int(ast.I16) ast.I32 = int(ast.I32) ast.I64 = int(ast.I64)
    ast.U8 = int(ast.U8) ast.U16 = int(ast.U16) ast.U32 = int(ast.U32) ast.U64 = int(ast.U64)
	typesize = {
		I8:1 , I16:2 , I32:4, I64:8,
		U8:1 , U16:2 , U32:4, U64:8,
	}
	//Parser::count = 1
	count = 1
}

class Parser{
    gvars # map[string]VarExpr global vars

    //stor all global function
    funcs        # map[string]Function
    extern_funcs # map[string]Function

    strs          # [gen.StringExpr]  all static string
    
    links         # [string] ld link args

    line column fileno

    pkg # Package*
    full_package # package name
    package      
    filename
    asmfile
    filepath

    //currently scanner
    scanner #Scanner*
    import  # map[string]string    full package path => user use path
}

Parser::init(filepath,pkg,package,full_package) {
    //init default env
    this.pkg = pkg
    this.currentFunc = null
    this.package = package
    this.filepath = filepath

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
    parse_err("parse: found token error token:%d:%s \n"
              "msg:%s\n"
              "line:%d column:%d file:%s\n",
              scanner.curToken,getTokenString(scanner.curToken),
              err,
              scanner.line,scanner.column,filepath)
    os.exit(-1)
}


Parser::isunary(){
    match scanner.curToken {
        std.SUB | ast.SUB | ast.LOGNOT | ast.BITNOT : {
            return true
        }
        _ : return false
    }
}
Parser::isprimary(){
    match scanner.curToken {
        ast.FLOAT  | ast.INT      | ast.CHAR     | ast.STRING | ast.VAR    | 
        ast.FUNC   | ast.LPAREN   | ast.LBRACKET | ast.LBRACE | ast.RBRACE | 
        ast.BOOL   | ast.EMPTY    | ast.NEW      | ast.DOT    | ast.DELREF |
        ast.BITAND | ast.BUILTIN : {
            return true
        }
        _ : return false
    }
}
Parser::ischain(){
    match this.scanner.curToken {
        ast.DOT | ast.LPAREN | ast.LBRACKET : {
            return true
        }
        _ : return false

    }
}
Parser::isassign(){
    match scanner.curToken {
        ast.ASSIGN | ast.ADD_ASSIGN | ast.SUB_ASSIGN | ast.MUL_ASSIGN |
        ast.DIV_ASSIGN | ast.MOD_ASSIGN | ast.BITAND_ASSIGN | ast.BITOR_ASSIGN | 
        ast.SHL_ASSIGN | ast.SHR_ASSIGN : {
            return true
        }
        _ : return false
    }
}
Parser::isbinary(){
    match scanner.curToken {
        ast.SHL | ast.SHR | ast.BITOR | ast.BITAND | ast.BITNOT | ast.LOGOR |  
        ast.LOGAND | ast.LOGNOT | ast.EQ | ast.NE | ast.GT | ast.GE | ast.LT |
        ast.LE | ast.ADD | ast.SUB | ast.MOD | ast.MUL | ast.DIV : {
            return true
        }
        _ : return false
    }
}
