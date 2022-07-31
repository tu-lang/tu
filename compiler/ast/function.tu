class Function {
    clsName
    name
    isExtern
    isObj
    structname
    rettype
    
    parser

    locals # map[string]VarExpr 
    params_var # map[string]VarExpr

    params_order_var # [VarExpr]
    
    is_variadic
    size
    stack
    l_stack
    g_stack
    
    stack_size
   
    closures # [Functions]
    receiver # ClosureExpr
   
    params   # [string]
    block   
    retExpr
}
