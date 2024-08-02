use string
use std
use compiler.ast
use compiler.parser.scanner
use compiler.utils
use runtime

EMPTY_STR = ""

I8  = int(ast.I8)  U8  = int(ast.U8) 
I16 = int(ast.I16) U16 = int(ast.U16) 
I32 = int(ast.I32) U32 = int(ast.U32)
I64 = int(ast.I64) U64 = int(ast.U64)
F32 = int(ast.F32) F64 = int(ast.F64)
typesize = {
    I8 : 1 , I16 : 2 , I32 : 4 , I64 : 8,
    U8 : 1 , U16 : 2 , U32 : 4 , U64 : 8,
    F32: 4 , F64 : 8
}
EOF = -1 //FXIME: EOF
count = 1 

class Parser {
    ctx 
    gvars = {} # map{string:VarExpr} global vars

    //stor all global function
    funcs = {}         // map{string:Function}
    extern_funcs = {}  // map[string]Function

    strs = {}          // string:StringExpr  all static string
    
    links = []         // [string] ld link args

    classes = {}       //[string]Class

    line column fileno

    pkg         = pkg   // Package*
    currentFunc = null
    filename   
    filenameid  = ""
    asmfile
    filepath    = filepath

    //currently scanner
    scanner        //Scanner*
    ismultiassign = false

    cfgs          = new ast.ConfigOpts()
}

Parser::init(filepath,pkg) {
    utils.debugf(
        "parser.Parser::init() filename:%s package:%s full_package:%s"
        filepath,pkg.package,pkg.full_package
    )
    fullname = std.pop(string.split(filepath,"/"))
    //this.filename = string.sub(fullname,0,std.len(fullname) - 3)
    this.filename = fullname
    this.asmfile  = this.filename + ".s"
    if pkg.package != "main"
        this.asmfile  = "co_" + pkg.getFullName() + "_" + this.asmfile
    
    this.scanner = new scanner.ScannerStatic(filepath,this)
    this.filenameid = this.label() + ".L.filename." +  ast.incr_labelid()

}
Parser::label(){
    return this.pkg.full_package
}
Parser::getImport(pkgname){
    return this.pkg.getImport(pkgname)
}
Parser::parse()
{
    reader<scanner.ScannerStatic> = this.scanner
    reader.scan()
    utils.debug("parser.Parser::parse() tk:%s",reader.curLex.dyn())

    loop {
        match reader.curToken  {
            ast.FUNC : {
                this.ctx = new ast.Context()
                f = this.parseFuncDef(false,false)
                this.ctx = null
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
            ast.CFG   : this.parseCfg()
            ast.END   : return null 
            _     : this.parseGlobalDef()
        }
    }
}
Parser::getpkgname()
{
    return this.pkg.full_package
}
//TODO: class member vardic args...
Parser::panic(err){
    fmt.println("Parser::panic:",)
    this.check(false,err)
}
Parser::check(check<runtime.Value> , err<i8*>)
{
    reader<scanner.ScannerStatic> = this.scanner
    //static
    if check == 1 return  null
    if check == 0 goto check_panic 
    //dyn
    c = check
    if c return null
check_panic:
    msg = err
    if err == null msg = ""
    os.dief (
        "parse: found token error token: %s \n" +
        "msg:%s \n" + 
        "line:%d column:%d file:%s\n",
        reader.curLex.dyn(),
        msg,
        int(reader.line),int(reader.column),this.filepath
    )
}
Parser::expect(tok<i32>,str){
    reader<scanner.ScannerStatic> = this.scanner
    if reader.curToken == tok {
        return  true
    }
    msg = EMPTY_STR
    if str != null {
        msg = str
    }
    err = fmt.sprintf(
        "parse: found token error token:%s(%s) expect:%s\n msg:%s\n line:%d column:%d file:%s\n",
        ast.getTokenString(reader.curToken),
        reader.curLex.dyn(),
        ast.getTokenString(tok),
        msg,int(reader.line),int(reader.column),this.filepath
    )
    os.panic(err)
}
Parser::next_expect(tk,err<i8*>){
    reader<scanner.ScannerStatic> = this.scanner
    reader.scan()
    return this.expect(tk,err)
}

Parser::lassigner(p){
    match type(p) {
        type(gen.VarExpr) : return true
        type(gen.ChainExpr) : return true
        type(gen.IndexExpr) : return true
        type(gen.MemberExpr): return true
        type(gen.DelRefExpr): return true
        type(gen.StructMemberExpr)  : return true
        _:{
            this.check(false,"ParseError: can not assign to " + p.name())
        }
    }
}

Parser::isunary(){
    reader<scanner.ScannerStatic> = this.scanner
    match reader.curToken {
        ast.SUB | ast.SUB | ast.LOGNOT | ast.BITNOT : {
            return true
        }
        _ : return false
    }
}
Parser::isprimary(){
    reader<scanner.ScannerStatic> = this.scanner
    match reader.curToken {
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
    reader<scanner.ScannerStatic> = this.scanner
    match reader.curToken {
        ast.DOT | ast.LPAREN | ast.LBRACKET : {
            return true
        }
        _ : return false
    }
}
Parser::isassign(){
    reader<scanner.ScannerStatic> = this.scanner
    match reader.curToken {
        ast.ASSIGN | ast.ADD_ASSIGN | ast.SUB_ASSIGN | ast.MUL_ASSIGN |
        ast.DIV_ASSIGN | ast.BITXOR_ASSIGN | ast.MOD_ASSIGN | ast.BITAND_ASSIGN | ast.BITOR_ASSIGN | 
        ast.SHL_ASSIGN | ast.SHR_ASSIGN : {
            return true
        }
        _ : return false
    }
}
Parser::isbinary(){
    reader<scanner.ScannerStatic> = this.scanner
    match reader.curToken {
        ast.SHL | ast.SHR | ast.BITOR | ast.BITXOR | ast.BITAND | ast.BITNOT | ast.LOGOR |  
        ast.LOGAND | ast.LOGNOT | ast.EQ | ast.NE | ast.GT | ast.GE | ast.LT |
        ast.LE | ast.ADD | ast.SUB | ast.MOD | ast.MUL | ast.DIV : {
            return true
        }
        _ : return false
    }
}
Parser::isbase(){
    reader<scanner.ScannerStatic> = this.scanner
    match reader.curToken {
        ast.I8 | ast.U8 | ast.I16 | ast.U16 |
        ast.I32| ast.U32| ast.I64 | ast.U64 :
            return true
        ast.F32 | ast.F64 : return true
    }
    return false
}

Parser::tolevelvar(var){
    if this.currentFunc == null  return true
    if var.package != "" return true

    realvar = this.getvar(var.varname)
    if realvar {
        var.isdefine = false
        var.varname = realvar.varname
    }
}

Parser::getvar(varname){
    if this.currentFunc == null return null

    varexpr = this.ctx.getVar(this.currentFunc,varname)

	if varexpr != null return varexpr

	return this.getGlobalVar("",varname)
}

Parser::newvar(var){
    if type(var) == type(gen.VarExpr) && this.currentFunc {
        if !var.isdefine {
            return true
        } 
        if var.package == "" && this.currentFunc.params_var[var.varname] == null {
            hascontext = this.ctx.hasVar(var.varname)
            if(hascontext != null){
                if(!this.getvar(var.varname))
                    this.check(false,"ctx has var , local doesn't has")
            }else{
                varname = var.varname
                this.currentFunc.InsertLocalVar(this.ctx.toplevel(),var)
                this.ctx.createVar(varname,var)
            }
        }
    }
}

Parser::add_string(str){
    if package.get_string(str) != null {
        return true
    }
    package.add_string(str)
    this.strs[str.lit] = str
}