use ast

Null  = null
True  = true
False = false
EmptyStr = ""

I8  = int(ast.I8)  U8  = int(ast.U8) 
I16 = int(ast.I16) U16 = int(ast.U16) 
I32 = int(ast.I32) U32 = int(ast.U32)
I64 = int(ast.I64) U64 = int(ast.U64)
typesize = {
    I8 : 1 , I16 : 2 , I32 : 4 , I64 : 8,
    U8 : 1 , U16 : 2 , U32 : 4 , U64 : 8
}

func exprIsMtype(cond,ctx){
    ismtype = false
    match type(cond) {
        type(StructMemberExpr) | type(DelRefExpr) | type(AddExpr): {
            ismtype = true
        }
        type(VarExpr) | type(BinaryExpr): {
            ismtype = cond.isMemtype(ctx)
        }
        type(ChainExpr): ismtype = cond.ismem(ctx)
        type(BuiltinFuncExpr) : ismtype = cond.isMem(ctx)
    }
    return ismtype
}