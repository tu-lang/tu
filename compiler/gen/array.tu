use utils
use ast
use internal
use compile
use parser
use parser.package

// @param ctx [Context]
// @return Expression
ast.ArrayExpr::compile(ctx){
    record()
    //new Array & push array
    internal.newobject(ast.Array, 0)

    compile.Push()

    for(element: this.literal){
        //new element & push element
        element.compile(ctx)
        compile.Push()

        internal.arr_pushone() 
    }

    //pop array
    compile.Pop("%rax")

    return null
}

ast.KVExpr::compile(ctx){
    record()
    utils.debug("KVExpr: gen... k:%s v:%s",key,value)

    //push key
    this.key.compile(ctx)
    compile.Push()
    //push value
    this.value.compile(ctx)
    compile.Push()
    return null
}

ast.IndexExpr::compile(ctx) {
    record()
    f = compile.currentFunc

    if varname == "" {
        this.index.compile(ctx)
        compile.Push()

        //call arr_get(arr,index)
        internal.kv_get()
        return null
    }
    var = null
    packagename = this.package

    if this.is_pkgcall {
        var = ast.getVar(ctx,packagename)
        if var != null {
            compile.GenAddr(var)
            compile.Load()
            compile.Push()

            internal.object_member_get(varname)
            compile.Push()

            goto INDEX
        }
        this.check(!std.exist(packagename,package.packages),"package not exist: " + package)

        var  = package.packages[packagename].getGlobalVar(varname)

        if var == null panic("AsmError:use of undefined global variable " + varname)
    }else{

        packagename = compile.currentFunc.parser.getpkgname()
        var  = package.packages[packagename].getGlobalVar(varname)
    }
    if var != null {
        compile.GenAddr(var)
        compile.Load()
        compile.Push()
INDEX:
        this.index.compile(ctx)
        compile.Push()

        //call arr_get(arr,index)
        internal.kv_get()
        return null
    }
    var = ast.getVar(ctx,this.varname)
    if var != null {
        compile.GenAddr(var)
        compile.Load()
        compile.Push()

        this.index.compile(ctx)
        compile.Push()

        internal.kv_get()
        return null
    }
    panic("AsmError: index-expr use of undefined variable " + varname)
}

