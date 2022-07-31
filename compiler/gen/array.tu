use utils
use ast
use internal
use compile
use parser

// @param ctx [Context]
// @return Expression
ArrayExpr::compile(ctx){
    record()
    //new Array & push array
    internal.newobject(ast.Array, 0)

    this.obj.push()

    for(element: this.literal){
        //new element & push element
        element.compile(ctx)
        this.obj.push()

        internal.arr_pushone() 
    }

    //pop array
    this.obj.pop("%rax")

    return null
}

KVExpr::compile(ctx){
    record()
    utils.debug("KVExpr: gen... k:%s v:%s",key,value)

    //push key
    this.key.compile(ctx)
    this.obj.push()
    //push value
    this.value.compile(ctx)
    this.obj.push()
    return null
}

IndexExpr::compile(ctx) {
    record()
    f = this.obj.currentFunc

    if varname == "" {
        this.index.compile(ctx)
        this.obj.push()

        //call arr_get(arr,index)
        internal.kv_get()
        return null
    }
    var = null
    package = this.package

    if this.is_pkgcall {
        var = ast.getVar(ctx.package)
        if var != null {
            this.obj.GenAddr(var)
            this.obj.Load()
            this.obj.Push()

            internal.object_member_get(varname)
            this.obj.Push()

            goto INDEX
        }
        this.check(!std.exist(parser.packages,package),"package not exist: " + package)

        var  = parser.packages[package].getGlobalVar(varname)

        if var == null panic("AsmError:use of undefined global variable " + varname)
    }else{

        package = this.obj.currentFunc.parser.getpkgname()
        var  = parser.packages[package].getGlobalVar(varname)
    }
    if var != null {
        this.obj.GenAddr(var)
        this.obj.Load()
        this.obj.Push()
INDEX:
        this.index.compile(ctx)
        this.obj.Push()

        //call arr_get(arr,index)
        internal.kv_get()
        return null
    }
    var = ast.getVar(ctx,this.varname)
    if var != null {
        this.obj.GenAddr(var)
        this.obj.Load()
        this.obj.Push()

        this.index.compile(ctx)
        this.obj.Push()

        internal.kv_get()
        return null
    }
    panic("AsmError: index-expr use of undefined variable " + varname)
}

