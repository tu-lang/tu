use ast
use compile
use utils


class MapExpr : ast.Ast { 
    lit 
    func init(line,column){
        super.init(line,column)
    }
}
MapExpr::toString() {
    str = "MapExpr(elements={"
    if std.len(lit) != 0 {
        for (e : lit) {
            str += e.toString()
        }
    }
    str += "})"
    return str
}
MapExpr::compile(ctx){
    this.record()
    utils.debug("MapExpr: gen... ")
    
    internal.newobject(ast.Map, 0)
    compile.Push()

    for(element: this.lit){
        
        element.compile(ctx)
        internal.kv_update()
    }

    compile.Pop("%rax")
    return null
}