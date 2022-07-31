MapExpr::compile(ctx){
    record()
    utils.debug("MapExpr: gen... ")
    
    internal.newobject(ast.Map, 0)
    Compiler::Push()

    for(element: this.literal){
        
        element.compile(ctx)
        internal.kv_update()
    }

    Compiler::Pop("%rax")
    return null
}