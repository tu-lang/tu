use compiler.utils
use compiler.ast
use compiler.internal
use compiler.compile
use compiler.parser
use compiler.parser.package

class ArrayExpr   : ast.Ast { 
    lit = []
    func init(line,column){
        super.init(line,column)
    }
}

// @param ctx [Context]
// @return Expression
ArrayExpr::compile(ctx,load){
    utils.debug("gen.ArrayExpr::compile()")
    this.record()
    //new Array & push array
    internal.newobject(ast.Array, 0)

    compile.Push()

    for(element: this.lit){
        compile.writeln("    push (%%rsp)")
        //new element & push element
        element.compile(ctx)
        compile.Push()

        internal.arr_pushone() 
    }

    //pop array
    compile.Pop("%rax")

    return null
}
ArrayExpr::toString() {
    str = "ArrayExpr(elements=["
    for e : this.lit  {
        str += e.toString()
    }
    str += "])"
    return str
}

