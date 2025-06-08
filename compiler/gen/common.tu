use compiler.ast
use compiler.compile

Null  = null
EmptyStr = ""

typeids = []
// I8  = int(ast.I8)  U8  = int(ast.U8) 
// I16 = int(ast.I16) U16 = int(ast.U16) 
// I32 = int(ast.I32) U32 = int(ast.U32)
// I64 = int(ast.I64) U64 = int(ast.U64)
// typesize = {
//     I8 : 1 , I16 : 2 , I32 : 4 , I64 : 8,
//     U8 : 1 , U16 : 2 , U32 : 4 , U64 : 8
// }
func init(){
    typeids = {
        "null":ast.Null , "int" : ast.Int , "double" : ast.Double, "string" : ast.String,
        "bool":ast.Bool , "char": ast.Char, "array"  : ast.Array , "map"    : ast.Map,
        "function": ast.Func
    }
}
func exprIsMtype(cond,ctx){
    ismtype = false
    match type(cond) {
        type(StructMemberExpr) | type(DelRefExpr) | type(AddrExpr): {
            ismtype = true
        }
        type(VarExpr) | type(BinaryExpr): {
            ismtype = cond.isMemtype(ctx)
        }
        type(ChainExpr): ismtype = cond.ismem(ctx)
        type(BuiltinFuncExpr) : ismtype = cond.isMem(ctx)
        type(IndexExpr): {
            i = cond
            if i.tyassert != null {
                ismtype = true
            }else{
                var = new VarExpr(i.varname,i.line,i.column)
                var.package = i.package
                ismtype = var.isMemtype(ctx)
            }
        }
        type(MemberExpr) : ismtype = cond.ismem(ctx)
        type(MemberCallExpr): ismtype = cond.ismem(ctx)
        type(FunCallExpr): {
            i = cond
            i.geninit(ctx)
            i.check(i.fcs != null," memtype check")
            if std.len(i.fcs.returnTypes) > 0 {
                ismtype = true
            }
        }
    }
    return ismtype
}
func GP(){
    return compile.currentParser
}
func GF(){
    return compile.currentFunc
}