Compiler::registerStrings()
{
    for(&var:parser.strs){
        r = "L" + ast.incr_compileridx() 
        var.name = r
        CreateGlobalString(var)
    }
}
Compiler::registerVars()
{
    for(name,v : parser.gvars){
        gname = parser.getpkgname() + "_" + name
        writeln("    .global %s",gname)
        writeln("%s:",gname)
        if !v.structtype {
            writeln("    .quad   8")
            continue
        }
        mt = "byte"
        value = v.ivalue == "" ? "0" : v.ivalue
        //TODO: support `|` multi condition match
        match v.type {
            ast.I8  | ast.U8  :  mt = "byte"
            ast.I16 | ast.U16 :  mt = "value"
            ast.I32 | ast.U32 :  mt = "long"
            ast.I64 | ast.U64 :  mt = "quad"
        }
        writeln("    .%s   %s",mt,value)
    }
}
Compiler::CreateGlobalString(StringExpr *var)
{
    writeln("%s:", var.name)
    writeln("    .\"%s\"",var.literal)
}
