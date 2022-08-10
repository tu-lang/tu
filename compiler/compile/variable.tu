use ast
use parser
use parser.package

func registerStrings(){
    for(var : parser.strs){
        r = "L" + ast.incr_lableid() 
        var.name = r
        CreateGlobalString(var)
    }
}
func registerVars(){
    for(name,v : parser.gvars){
        gname = parser.getpkgname() + "_" + name
        writeln("    .global %s",gname)
        writeln("%s:",gname)
        if !v.structtype {
            writeln("    .quad   8")
            continue
        }
        mt = "byte"
        value = "0"
        if !std.empty(v.ivalue) value = v.ivalue
        //TODO: value = v.ivalue == "" ? "0" : v.ivalue
        match v.type {
            ast.I8  | ast.U8  :  mt = "byte"
            ast.I16 | ast.U16 :  mt = "value"
            ast.I32 | ast.U32 :  mt = "long"
            ast.I64 | ast.U64 :  mt = "quad"
        }
        writeln("    .%s   %s",mt,value)
    }
}
func CreateGlobalString(var){
    writeln("%s:", var.name)
    writeln("    .\"%s\"",var.literal)
}
