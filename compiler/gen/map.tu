use ast
use compile
use utils


ast.MapExpr::compile(ctx){
    record()
    utils.debug("MapExpr: gen... ")
    
    internal.newobject(ast.Map, 0)
    compile.Push()

    for(element: this.literal){
        
        element.compile(ctx)
        internal.kv_update()
    }

    compile.Pop("%rax")
    return null
}