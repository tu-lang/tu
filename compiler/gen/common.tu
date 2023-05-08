use compiler.ast
use compiler.compile

Null  = null
EmptyStr = ""

// I8  = int(ast.I8)  U8  = int(ast.U8) 
// I16 = int(ast.I16) U16 = int(ast.U16) 
// I32 = int(ast.I32) U32 = int(ast.U32)
// I64 = int(ast.I64) U64 = int(ast.U64)
// typesize = {
//     I8 : 1 , I16 : 2 , I32 : 4 , I64 : 8,
//     U8 : 1 , U16 : 2 , U32 : 4 , U64 : 8
// }
typeids = {
    "null":int(ast.Null) , "int" : int(ast.Int) , "double" : int(ast.Double), "string" : int(ast.String),
    "bool":int(ast.Bool) , "char": int(ast.Char), "array"  : int(ast.Array) , "map"    : int(ast.Map)
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
    }
    return ismtype
}
func check_load(ctx,expr,ret){
    if !exprIsMtype(expr,ctx) {
        return true
	}
	if type(ret) == type(StructMemberExpr) 
	{
		m = ret
		v = m.getMember() 
		
		if type(expr) != type(AddrExpr) && type(expr) != type(DelRefExpr){
			compile.LoadMember(v)
		}
	}else if type(ret) == type(ChainExpr) {
		m = ret
		v = m.ret
		
		if type(expr) == type(AddrExpr) {
			
		}else if type(expr) == type(DelRefExpr) {
			compile.LoadSize(v.size,v.isunsigned)
		}else if type(m.last) == type(IndexExpr) {
			compile.LoadSize(v.size,v.isunsigned)
		}else if type(m.last) == type(MemberCallExpr) {
		}else{
			compile.LoadMember(v)
		}
	}
    return true
}
func GP(){
    return compile.currentParser
}
func GF(){
    return compile.currentFunc
}