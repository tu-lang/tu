use compiler.ast
use compiler.compile
use compiler.utils


class MapExpr : ast.Ast { 
    lit = []
    func init(line,column){
        super.init(line,column)
    }
}
MapExpr::toString() {
    str = "MapExpr(elements={"
    if std.len(this.lit) != 0 {
        for (e : this.lit) {
            str += e.toString()
        }
    }
    str += "})"
    return str
}
MapExpr::compile(ctx,load){
    this.record()
    utils.debug("gen.MapExpr::compile() ")
    
    internal.newobject(ast.Map, 0)
    compile.Push()

    for(element: this.lit){
        compile.writeln("    push (%%rsp)")
        element.compile(ctx)
        internal.kv_update()
    }

    compile.Pop("%rax")
    return null
}