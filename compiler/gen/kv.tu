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
    if this.key   str += this.key.toString()
    str += ":"
    if this.value str += this.value.toString()
    str += "}"
    return str
}

KVExpr::compile(ctx){
    this.record()
    utils.debug("KVExpr: gen... k:%s v:%s",this.key,this.value)

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
    if this.index
        str += this.index.toString()
    str += ")"
    return str
}



IndexExpr::compile(ctx) {
    this.record()
    f = compile.currentFunc

    if this.varname == "" {
        this.index.compile(ctx)
        compile.Push()

        //call arr_get(arr,index)
        internal.kv_get()
        return null
    }
    var = null
    packagename = this.package

    if this.is_pkgcall {
        this.check(!std.exist(packagename,package.packages),"package not exist: " + this.package)

        var  = package.packages[packagename].getGlobalVar(this.varname)

        if var == null this.panic("AsmError:use of undefined global variable " + this.varname)
    }else if (var = ast.getVar(ctx,this.package))  && var != null {
        compile.GenAddr(var)
        compile.Load()
        compile.Push()
        internal.object_member_get(this.varname)
        compile.Push()
        goto INDEX
    }else {

        packagename = compile.currentFunc.parser.getpkgname()
        var  = package.packages[packagename].getGlobalVar(this.varname)
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
    this.panic("AsmError: index-expr use of undefined variable " + this.varname)
}

IndexExpr::assign( ctx , opt ,rhs) {
    f = compile.currentFunc   
    varname = this.varname
    varExpr = null
    package    = compile.currentFunc.parser.getpkgname()
    is_member = false
    if this.is_pkgcall {
        this.check(std.exist(package,package.packages),"package not found:" + package)
        varExpr = package.packages[package].getGlobalVar(varname)
        if varExpr == null  this.panic("AsmError:use of undefined global variable" + varname)
    } else if std.exist(this.package,f.params_var)  || std.exist(this.package,f.locals) {
        is_member = true
        if f.params_var[this.package] != null 
            varExpr = f.params_var[this.package]
        else    
            varExpr = f.locals[this.package]
    }else if(package.packages[package].getGlobalVar(varname)){
        varExpr = package.packages[package].getGlobalVar(varname)
    }else if(f.params_var[varname] != null ) {
        varExpr = f.params_var[varname]
    }else{
        varExpr = f.locals[varname]
    }
    if varExpr == null
        this.panic(
            "SyntaxError: not find variable %s at line:%d, column:%d file:%s\n", 
            varname,this.line,this.column,this.compile.currentFunc.parser.filepath
        )
    std.tail(ctx).createVar(varExpr.varname,varExpr)
    compile.GenAddr(varExpr)
    compile.Load()
    compile.Push()
    if is_member {
        internal.object_member_get(varname)
        compile.Push()
    }
    if this.index == null {
        rhs.compile(ctx)
        compile.Push()
        internal.arr_pushone()
        compile.Pop("%rdi")
        return null
    }
    this.index.compile(ctx)
    compile.Push()
    rhs.compile(ctx)
    compile.Push()
    //call arr_updateone(arr,index,var)
    internal.kv_update()
    //rm unuse 
    compile.Pop("%rdi")
    return null
    
}
