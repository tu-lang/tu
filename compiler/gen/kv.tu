use utils
use ast
use internal
use compile
use parser
use parser.package

class KVExpr  : ast.Ast { 
	key value 
	func init(line,column){
		super.init(line,column)
	}
}
KVExpr::toString() {
    str = "{"
    if (key)   str += key.toString()
    str += ":"
    if (value) str += value.toString()
    str += "}"
    return str
}

KVExpr::compile(ctx){
    this.record()
    utils.debug("KVExpr: gen... k:%s v:%s",key,value)

    //push key
    this.key.compile(ctx)
    compile.Push()
    //push value
    this.value.compile(ctx)
    compile.Push()
    return null
}

class IndexExpr : ast.Ast {
    varname
    index
    is_pkgcall
    package
    func init(line,column){
        super.init(line,column)
    }
}
IndexExpr::toString() {
    str = "IndexExpr(index="
    if index
        str += index.toString()
    str += ")"
    return str
}



IndexExpr::compile(ctx) {
    this.record()
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

        if var == null this.panic("AsmError:use of undefined global variable " + varname)
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
    this.panic("AsmError: index-expr use of undefined variable " + varname)
}

