use parser
use std
use fmt
use ast

NullExpr::compile(ctx)
{
    record()
    internal.newobject(ast.Null,0)
    return null

}
BoolExpr::compile(ctx)
{
    record()
    internal.newobject(ast.Bool,this.literal)
    return null
}
CharExpr::compile(ctx) {
    record()
    internal.newobject(ast.Char,this.literal)
    return null
}
IntExpr::compile( ctx) {
    record()
    internal.newint(ast.Int,this.literal)
    return null
}

DoubleExpr::compile(ctx) {
    record()
    internal.newobject(ast.Double,this.literal)
    return null
}

StringExpr::compile(ctx) {
    record()
    if this.name != "" this.check(false,this.toString())
    
    this.obj.writeln("    lea %s(%%rip), %%rsi", name)
    internal.newobject(ast.String,0)
    return null
}

Expression::record(){
    cfunc = this.obj.currentFunc
    this.obj.writeln("# line:%d column:%d file:%s",line,column,cfunc.parser.filepath)
}
Statement::record(){
    cfunc = this.obj.currentFunc
    this.obj.writeln("# line:%d column:%d file:%s",line,column,cfunc.parser.filepath)
}
Expression::panic(err){
    cfunc = this.obj.currentFunc
    parse_err("asmgen error: %s line:%d column:%d file:%s\n",err,line,column,cfunc.parser.filepath)
}
Expression::check( check , err)
{
    if(check) return err 

    cfunc = this.obj.currentFunc
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