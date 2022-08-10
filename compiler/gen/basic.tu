use parser
use std
use fmt
use ast
use compile

ast.NullExpr::compile(ctx)
{
    record()
    internal.newobject(ast.Null,0)
    return null

}
ast.BoolExpr::compile(ctx)
{
    record()
    internal.newobject(ast.Bool,this.literal)
    return null
}
ast.CharExpr::compile(ctx) {
    record()
    internal.newobject(ast.Char,this.literal)
    return null
}
ast.IntExpr::compile( ctx) {
    record()
    internal.newint(ast.Int,this.literal)
    return null
}

ast.DoubleExpr::compile(ctx) {
    record()
    internal.newobject(ast.Double,this.literal)
    return null
}

ast.StringExpr::compile(ctx) {
    record()
    if this.name != "" this.check(false,this.toString())
    
    compile.writeln("    lea %s(%%rip), %%rsi", name)
    internal.newobject(ast.String,0)
    return null
}

ast.Expression::record(){
    cfunc = compile.currentFunc
    compile.writeln("# line:%d column:%d file:%s",line,column,cfunc.parser.filepath)
}
ast.Statement::record(){
    cfunc = compile.currentFunc
    compile.writeln("# line:%d column:%d file:%s",line,column,cfunc.parser.filepath)
}
ast.Expression::panic(args...){
    err = fmt.sprintf(args)
    cfunc = compile.currentFunc
    parse_err("asmgen error: %s line:%d column:%d file:%s\n",err,line,column,cfunc.parser.filepath)
}
ast.Expression::check( check , err)
{
    if(check) return err 

    cfunc = compile.currentFunc
    if err != "" {
        fmt.println("AsmError:%s \n"
                "line:%d column:%d file:%s\n\n"
                "expression:\n%s\n",err,line,column,cfunc.parser.filepath,this.toString())
    }else{
        fmt.println("AsmError:\n"
                "line:%d column:%d file:%s\n\n"
                "expression:\n%s\n",line,column,cfunc.parser.filepath,this.toString())
    }
    os.exit(-1)
}