use utils
use ast
use internal
use compile
use parser
use parser.package

class ArrayExpr   : ast.Ast { 
    lit 
    func init(line,column){
        super.init(line,column)
    }
}

// @param ctx [Context]
// @return Expression
ArrayExpr::compile(ctx){
    record()
    //new Array & push array
    internal.newobject(ast.Array, 0)

    compile.Push()

    for(element: this.lit){
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
    if std.len(lit) != 0 {
        for (e : lit) {
            str += e.toString()
        }
    }
    str += "])"
    return str
}

